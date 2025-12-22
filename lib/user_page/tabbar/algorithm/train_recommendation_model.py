# train_recommendation_model.py
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import os
import pickle
import logging
import sqlite3
from typing import List, Dict, Optional

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class PCRecommendationTrainer:
    """
    Simple PC component recommendation system
    """
    
    def __init__(self, db_path: str = "assemble_db.db", datasets_path: str = "./datasets"):
        self.db_path = db_path
        self.datasets_path = datasets_path
        self.components_df = None
        self.tfidf_vectorizer = None
        self.tfidf_matrix = None
        self.similarity_matrix = None
        
        # Map category names to actual database table names
        self.table_mapping = {
            'cpu': 'CPUtable',
            'gpu': 'GPUtable', 
            'psu': 'PSUtable',
            'cooling': 'coolingtable',
            'motherboard': 'motherboardtable',
            'storage': 'storagetable',
            'case': 'casetable',
            'ram': 'RAMtable'
        }
        
    def check_datasets_available(self) -> bool:
        """
        Check if all dataset files are available in /datasets path
        """
        required_datasets = [
            'cpu_dataset.csv', 'gpu_dataset.csv', 'motherboard_dataset.csv',
            'ram_dataset.csv', 'storage_dataset.csv', 'psu_dataset.csv', 
            'case_dataset.csv', 'cooling_dataset.csv'
        ]
        
        missing_files = []
        for filename in required_datasets:
            file_path = os.path.join(self.datasets_path, filename)
            if not os.path.exists(file_path):
                missing_files.append(filename)
        
        if missing_files:
            logger.error(f" Missing dataset files: {missing_files}")
            return False
        
        logger.info(" All dataset files are available")
        return True
        
    def check_component_in_database(self, component_id: int, category: str) -> bool:
    
        try:
            # Get the actual table name from mapping
            table_name = self.table_mapping.get(category)
            if not table_name:
                logger.error(f" Unknown category: {category}")
                return False
            
            # Check if database file exists
            if not os.path.exists(self.db_path):
                logger.warning(f" Database file not found: {self.db_path}")
                return False
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # FIXED: Use parameterized query properly
            query = f"SELECT COUNT(*) FROM {table_name} WHERE id = ?"
            cursor.execute(query, (component_id,))
            count = cursor.fetchone()[0]
            conn.close()
            
            exists = count > 0
            
            # DEBUG logging
            if exists:
                logger.info(f" {category} ID {component_id} found in database")
            else:
                logger.info(f" {category} ID {component_id} NOT in database")
            
            return exists
            
        except Exception as e:
            logger.error(f" Error checking database for component {component_id} in {category}: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return False

    
    def check_build_components_in_database(self, current_build: dict) -> bool:
        """
        Check if all components in current build exist in database
        """
        # If database doesn't exist, skip checks for now
        if not os.path.exists(self.db_path):
            logger.warning(" Database file not found, skipping component checks")
            return True
            
        all_exist = True
        for category, component_id in current_build.items():
            if not self.check_component_in_database(component_id, category):
                all_exist = False
                logger.error(f" Build component missing: {category} ID {component_id}")
        return all_exist

    def load_database_components(self) -> pd.DataFrame:
        """Load components from SQLite database"""
        logger.info(" Loading components from database...")
        
        if not os.path.exists(self.db_path):
            logger.warning(f"Database file not found: {self.db_path}")
            return pd.DataFrame()
        
        all_db_components = []
        
        # Database table to category mapping
        db_configs = {
            'CPUtable': {
                'category': 'cpu',
                'features': ['brand', 'socket', 'cores', 'threads', 'baseclock', 'boostclock', 'tdp', 'integratedgraphics']
            },
            'GPUtable': {
                'category': 'gpu',
                'features': ['brand', 'vram', 'core_clock', 'boostclock', 'tdp', 'length_mm']
            },
            'motherboardtable': {
                'category': 'motherboard',
                'features': ['brand', 'socket', 'chipset', 'form_factor', 'memory_type', 'memory_slots', 'max_memory']
            },
            'RAMtable': {
                'category': 'ram',
                'features': ['memory_type', 'capacity', 'speed', 'modules']
            },
            'storagetable': {
                'category': 'storage',
                'features': ['brand', 'interface', 'capacity', 'type']
            },
            'PSUtable': {
                'category': 'psu',
                'features': ['brand', 'wattage', 'form_factor', 'efficiency_rating']
            },
            'casetable': {
                'category': 'case',
                'features': ['brand', 'form_factor', 'max_gpu_length', 'estimated_power']
            },
            'coolingtable': {
                'category': 'cooling',
                'features': ['type', 'supported_sockets']
            }
        }
        
        try:
            conn = sqlite3.connect(self.db_path)
            
            for table_name, config in db_configs.items():
                category = config['category']
                features = config['features']
                
                try:
                    # Load all components from this table
                    query = f"SELECT * FROM {table_name}"
                    df = pd.read_sql_query(query, conn)
                    
                    if not df.empty:
                        # Add category column
                        df['category'] = category
                        
                        # Create feature text for similarity matching
                        df['feature_text'] = self._create_feature_text(df, features)
                        
                        # Mark as in database
                        df['in_database'] = True
                        
                        all_db_components.append(df)
                        logger.info(f"Loaded {len(df)} {category} components from database")
                    else:
                        logger.info(f" No {category} components found in database")
                        
                except Exception as e:
                    logger.warning(f" Error loading {table_name}: {e}")
                    continue
            
            conn.close()
            
            if all_db_components:
                combined_db_df = pd.concat(all_db_components, ignore_index=True)
                logger.info(f" Loaded {len(combined_db_df)} total components from database")
                return combined_db_df
            else:
                logger.info(" No components found in database")
                return pd.DataFrame()
                
        except Exception as e:
            logger.error(f"Error loading database components: {e}")
            return pd.DataFrame()

    def load_and_combine_datasets(self) -> pd.DataFrame:
    
        logger.info(" Loading component datasets from /datasets and database...")

        # Load dataset files
        all_components = []
        
        # Check if datasets are available (warn but don't fail if missing)
        datasets_available = self.check_datasets_available()
        
        # Dataset configurations - using only technical features (no images needed)
        datasets = {
            'cpu_dataset.csv': {
                'features': ['brand', 'socket', 'cores', 'threads', 'baseclock', 'boostclock', 'tdp', 'integratedgraphics'],
                'category': 'cpu'
            },
            'gpu_dataset.csv': {
                'features': ['brand', 'vram', 'core_clock', 'boostclock', 'tdp', 'length_mm'],
                'category': 'gpu'
            },
            'motherboard_dataset.csv': {
                'features': ['brand', 'socket', 'chipset', 'form_factor', 'memory_type', 'memory_slots', 'max_memory'],
                'category': 'motherboard'
            },
            'ram_dataset.csv': {
                'features': ['memory_type', 'capacity', 'speed', 'modules'],
                'category': 'ram'
            },
            'storage_dataset.csv': {
                'features': ['brand', 'interface', 'capacity', 'type'],
                'category': 'storage'
            },
            'psu_dataset.csv': {
                'features': ['brand', 'wattage', 'form_factor', 'efficiency_rating'],
                'category': 'psu'
            },
            'case_dataset.csv': {
                'features': ['brand', 'form_factor', 'max_gpu_length', 'estimated_power'],
                'category': 'case'
            },
            'cooling_dataset.csv': {
                'features': ['type', 'supported_sockets'],
                'category': 'cooling'
            }
        }
        
        # Load from dataset files
        if datasets_available:
            for filename, config in datasets.items():
                file_path = os.path.join(self.datasets_path, filename)
                try:
                    df = pd.read_csv(file_path)
                    category = config['category']
                    features = config['features']

                    logger.info(f" Loading {len(df)} {category} components from {filename}")
                    
                    # Add category column
                    df['category'] = category
                    
                    # Mark as not in database (dataset only)
                    df['in_database'] = False
                    
                    # Create feature text for similarity matching (only technical specs)
                    df['feature_text'] = self._create_feature_text(df, features)
                    all_components.append(df)
                    
                    logger.info(f" Loaded {len(df)} {category} components from dataset")
                    
                except Exception as e:
                    logger.error(f" Error loading {filename}: {e}")
                    # Don't raise, continue with other files
        else:
            logger.warning(" Dataset files not available, loading only from database")
        
        # Load from database
        db_components = self.load_database_components()
        if not db_components.empty:
            all_components.append(db_components)
            logger.info(f" Added {len(db_components)} database components to training data")
        
        if not all_components:
            logger.error(" No components loaded from datasets or database!")
            raise Exception("No components loaded from datasets or database")
        
        combined_df = pd.concat(all_components, ignore_index=True)
        logger.info(f" Combined dataset: {len(combined_df)} total components")
        logger.info(f" Breakdown by category:")
        for category in combined_df['category'].unique():
            cat_df = combined_df[combined_df['category'] == category]
            db_count = len(cat_df[cat_df.get('in_database', False) == True])
            dataset_count = len(cat_df[cat_df.get('in_database', False) == False])
            logger.info(f"   - {category}: {len(cat_df)} total ({db_count} from DB, {dataset_count} from dataset)")
        
        if combined_df.empty:
            logger.error(" No components loaded! Check your dataset files and database.")
            raise Exception("No components loaded from datasets or database")
        
        return combined_df

    
    def _create_feature_text(self, df: pd.DataFrame, features: list) -> pd.Series:
        """
        Create text from features for similarity matching
        """
        def create_text(row):
            text_parts = []
            for feature in features:
                if feature in row and pd.notna(row[feature]):
                    value = str(row[feature]).lower().replace('_', ' ')
                    text_parts.append(f"{feature} {value}")
            return " ".join(text_parts)
        
        return df.apply(create_text, axis=1)
    
    def train_model(self, df: pd.DataFrame):
        """
        Train the recommendation model
        """
        logger.info("Training recommendation model...")
        
        # Create TF-IDF vectors
        self.tfidf_vectorizer = TfidfVectorizer(
            max_features=500,
            stop_words='english',
            ngram_range=(1, 2)
        )
        
        self.tfidf_matrix = self.tfidf_vectorizer.fit_transform(df['feature_text'])
        self.components_df = df
        
        logger.info(f" Model trained with {self.tfidf_matrix.shape[1]} features")
    
    def calculate_similarity_matrix(self) -> np.ndarray:
        """
        Calculate cosine similarity matrix between all components
        """
        logger.info("Calculating cosine similarity matrix...")
        
        if self.tfidf_matrix is None:
            raise Exception("TF-IDF matrix not available. Train model first.")
        
        # Calculate cosine similarity
        self.similarity_matrix = cosine_similarity(self.tfidf_matrix)
        
        logger.info(f" Similarity matrix shape: {self.similarity_matrix.shape}")
        return self.similarity_matrix

    def get_similar_components(self, component_id: int, category: str, n_recommendations: int = 5, strict: bool = False):
        """
        Get similar components based on features
        """
        if strict:
            return self.get_similar_components_strict(component_id, category, n_recommendations)
        else:
            return self.get_similar_components_with_availability(component_id, category, n_recommendations)
    
    def get_similar_components_strict(self, component_id: int, category: str, n_recommendations: int = 5):
        """
        Get similar components - ONLY those available in database
        """
        if self.tfidf_matrix is None:
            raise Exception(" Model not trained!")
        
        # Find component index
        component_idx = self.components_df[self.components_df['id'] == component_id].index
        if len(component_idx) == 0:
            logger.warning(f" Component ID {component_id} not found in training data")
            return []
        
        component_idx = component_idx[0]
        
        # Calculate similarities
        similarity_scores = list(enumerate(cosine_similarity(self.tfidf_matrix)[component_idx]))
        similarity_scores = sorted(similarity_scores, key=lambda x: x[1], reverse=True)
        
        # Get top recommendations - ONLY from database
        recommendations = []
        for idx, score in similarity_scores[1:]:  # Skip the first (itself)
            if len(recommendations) >= n_recommendations:
                break
                
            if idx < len(self.components_df):
                component = self.components_df.iloc[idx]
                rec_id = int(component['id'])
                rec_category = component['category']
                
                # STRICT CHECK: Only include if in database
                if self.check_component_in_database(rec_id, rec_category):
                    recommendations.append({
                        'id': rec_id,
                        'model_name': component['model_name'],
                        'category': rec_category,
                        'price': int(component.get('price', 0)),
                        'similarity_score': float(score),
                        'brand': component.get('brand', ''),
                        'in_database': True,
                        'availability_status': 'Available in store',
                        'reason': self._generate_recommendation_reason(component, score)
                    })
        
        logger.info(f" Found {len(recommendations)} similar recommendations (STRICT MODE - ALL IN DATABASE)")
        return recommendations
    
    def get_similar_components_with_availability(self, component_id: int, category: str, n_recommendations: int = 5):
   
        if self.tfidf_matrix is None:
            raise Exception("Model not trained!")
        
        # Find component index
        component_idx = self.components_df[self.components_df['id'] == component_id].index
        if len(component_idx) == 0:
            logger.warning(f"Component ID {component_id} not found in training data")
            return []
        
        component_idx = component_idx[0]
        
        # Calculate similarities for SAME CATEGORY only
        same_category_df = self.components_df[self.components_df['category'] == category]
        if same_category_df.empty:
            logger.warning(f"No {category} components in training data")
            return []
        
        logger.info(f" Finding similar {category} components from {len(same_category_df)} total")
        
        # Get indices for same category
        category_indices = same_category_df.index.tolist()
        
        # Calculate similarities only within same category
        similarities = []
        for idx in category_indices:
            if idx != component_idx:  # Skip itself
                sim_score = cosine_similarity(
                    self.tfidf_matrix[component_idx:component_idx+1],
                    self.tfidf_matrix[idx:idx+1]
                )[0][0]
                similarities.append((idx, sim_score))
        
        # Sort by similarity
        similarities.sort(key=lambda x: x[1], reverse=True)
        
        # Get top recommendations and check database availability
        recommendations = []
        for idx, score in similarities[:n_recommendations * 2]:  # Get 2x more for filtering
            component = self.components_df.iloc[idx]
            rec_id = int(component['id'])
            rec_category = component['category']
            
            # Check if component exists in database
            in_database = self.check_component_in_database(rec_id, rec_category)
            
            recommendations.append({
                'id': rec_id,
                'model_name': component['model_name'],
                'category': rec_category,
                'price': int(component.get('price', 0)),
                'similarity_score': float(score),
                'brand': component.get('brand', ''),
                'in_database': in_database,
                'availability_status': 'Available in store' if in_database else 'Reference only - Not in database',
                'reason': self._generate_recommendation_reason(component, score)
            })
            
            if len(recommendations) >= n_recommendations:
                break
        
        db_count = sum(1 for r in recommendations if r['in_database'])
        dataset_count = len(recommendations) - db_count
        logger.info(f" Found {len(recommendations)} similar {category} recommendations ({db_count} in DB, {dataset_count} reference)")
        
        return recommendations

    def get_compatible_components(self, current_build: dict, target_category: str, n_recommendations: int = 5, strict: bool = False):
        """
        Get compatible components for current build
        """
        if strict:
            return self.get_compatible_components_strict(current_build, target_category, n_recommendations)
        else:
            return self.get_compatible_components_with_availability(current_build, target_category, n_recommendations)
    
    def get_compatible_components_strict(self, current_build: dict, target_category: str, n_recommendations: int = 5):
        """
        Get compatible components - ONLY those available in database
        """
        target_components = self.components_df[self.components_df['category'] == target_category]
        
        if target_components.empty:
            logger.warning(f" No {target_category} components found in training data")
            return []
        
        # Calculate compatibility scores
        compatibility_scores = []
        for idx, component in target_components.iterrows():
            score = self._calculate_compatibility(component, current_build)
            compatibility_scores.append((idx, score))
        
        # Sort and get top recommendations
        compatibility_scores.sort(key=lambda x: x[1], reverse=True)
        
        recommendations = []
        for idx, score in compatibility_scores:
            if len(recommendations) >= n_recommendations:
                break
                
            component = self.components_df.iloc[idx]
            rec_id = int(component['id'])
            
            # STRICT CHECK: Only include if in database
            if self.check_component_in_database(rec_id, target_category):
                recommendations.append({
                    'id': rec_id,
                    'model_name': component['model_name'],
                    'category': component['category'],
                    'price': int(component.get('price', 0)),
                    'compatibility_score': float(score),
                    'brand': component.get('brand', ''),
                    'in_database': True,
                    'availability_status': 'Available in store',
                    'compatibility_notes': self._generate_compatibility_notes(component, current_build),
                    'reason': self._generate_recommendation_reason(component, score)
                })
        
        logger.info(f" Found {len(recommendations)} compatible recommendations (STRICT MODE - ALL IN DATABASE)")
        return recommendations
    
    def get_compatible_components_with_availability(self, current_build: dict, target_category: str, n_recommendations: int = 5):
    
        target_components = self.components_df[self.components_df['category'] == target_category]
        
        if target_components.empty:
            logger.warning(f" No {target_category} components found in training data")
            logger.warning(f"Available categories: {self.components_df['category'].unique().tolist()}")
            return []
        
        logger.info(f" Finding compatible {target_category} from {len(target_components)} components")
        
        # Calculate compatibility scores
        compatibility_scores = []
        for idx, component in target_components.iterrows():
            score = self._calculate_compatibility(component, current_build)
            compatibility_scores.append((idx, score))
        
        # Sort and get top recommendations
        compatibility_scores.sort(key=lambda x: x[1], reverse=True)
        
        # Separate database and dataset recommendations
        database_recs = []
        dataset_recs = []
        
        for idx, score in compatibility_scores:
            component = self.components_df.iloc[idx]
            rec_id = int(component['id'])
            
            # Check if in database (use the in_database column if available, otherwise check)
            in_database = component.get('in_database', False)
            if pd.isna(in_database):
                in_database = self.check_component_in_database(rec_id, target_category)
            
            rec_dict = {
                'id': rec_id,
                'model_name': component['model_name'],
                'category': component['category'],
                'price': int(component.get('price', 0)),
                'compatibility_score': float(score),
                'brand': component.get('brand', ''),
                'in_database': bool(in_database),
                'availability_status': 'Available in store' if in_database else 'Reference only - Not in database',
                'compatibility_notes': self._generate_compatibility_notes(component, current_build),
                'reason': self._generate_recommendation_reason(component, score)
            }
            
            if in_database:
                if len(database_recs) < n_recommendations:
                    database_recs.append(rec_dict)
            else:
                if len(dataset_recs) < n_recommendations:
                    dataset_recs.append(rec_dict)
            
            # Stop when we have enough of both types
            if len(database_recs) >= n_recommendations and len(dataset_recs) >= n_recommendations:
                break
        
        logger.info(f"Found {len(database_recs)} database and {len(dataset_recs)} dataset {target_category} recommendations")
        
        # Return database recommendations first, then dataset
        return database_recs + dataset_recs
    
    def get_compatible_recommendations(self, current_build: dict, target_category: str, df: pd.DataFrame, similarity_matrix: np.ndarray, n_recommendations: int = 5, strict: bool = False):
        """
        Alias for get_compatible_components for backward compatibility
        """
        return self.get_compatible_components(current_build, target_category, n_recommendations, strict)
    
    def get_recommendations_from_database(self, component_id: int, category: str, n_recommendations: int = 5):
        """
        Get recommendations by first querying database, then finding similar
        """
        # First get all available components of same category from database
        table_name = self.table_mapping.get(category)
        if not table_name:
            return []
        
        conn = sqlite3.connect(self.db_path)
        query = f"SELECT * FROM {table_name}"
        available_components = pd.read_sql_query(query, conn)
        conn.close()
        
        if available_components.empty:
            return []
        
        # Find the target component in training data
        target_component = self.components_df[self.components_df['id'] == component_id]
        if target_component.empty:
            return []
        
        # Calculate similarity with all available components
        recommendations = []
        target_features = self.tfidf_vectorizer.transform([target_component.iloc[0]['feature_text']])
        
        for _, db_component in available_components.iterrows():
            if db_component['id'] == component_id:
                continue  # Skip itself
                
            # Find this component in training data for feature comparison
            train_component = self.components_df[self.components_df['id'] == db_component['id']]
            if not train_component.empty:
                comp_features = self.tfidf_vectorizer.transform([train_component.iloc[0]['feature_text']])
                similarity = cosine_similarity(target_features, comp_features)[0][0]
                
                recommendations.append({
                    'id': db_component['id'],
                    'model_name': db_component.get('model_name', ''),
                    'category': category,
                    'price': db_component.get('price', 0),
                    'similarity_score': float(similarity),
                    'brand': db_component.get('brand', ''),
                    'in_database': True,
                    'availability_status': 'Available in store'
                })
        
        # Sort by similarity and return top N
        recommendations.sort(key=lambda x: x['similarity_score'], reverse=True)
        return recommendations[:n_recommendations]
    
    def _calculate_compatibility(self, component: pd.Series, current_build: dict) -> float:
        """Calculate compatibility score (0-1) - UPDATED VERSION"""
        score = 0.0
        category = component['category']
        
        # CPU compatibility
        if category == 'cpu' and 'motherboard' in current_build:
            mobo_id = current_build['motherboard']
            mobo = self.components_df[self.components_df['id'] == mobo_id]
            if not mobo.empty and mobo.iloc[0]['socket'] == component.get('socket'):
                score += 0.5
        
        # RAM compatibility  
        elif category == 'ram' and 'motherboard' in current_build:
            mobo_id = current_build['motherboard']
            mobo = self.components_df[self.components_df['id'] == mobo_id]
            if not mobo.empty and mobo.iloc[0]['memory_type'] == component.get('memory_type'):
                score += 0.5
        
        # GPU compatibility
        elif category == 'gpu':
            if 'case' in current_build:
                case_id = current_build['case']
                case = self.components_df[self.components_df['id'] == case_id]
                if not case.empty and case.iloc[0]['max_gpu_length'] >= component.get('length_mm', 0):
                    score += 0.3
            
            if 'psu' in current_build:
                psu_id = current_build['psu']
                psu = self.components_df[self.components_df['id'] == psu_id]
                if not psu.empty and psu.iloc[0]['wattage'] >= component.get('tdp', 0) + 100:
                    score += 0.2
        
        # STORAGE compatibility - NEW
        elif category == 'storage' and 'motherboard' in current_build:
            mobo_id = current_build['motherboard']
            mobo = self.components_df[self.components_df['id'] == mobo_id]
            if not mobo.empty:
                storage_interface = component.get('interface', '').lower()
                
                # Check interface compatibility
                if 'm.2' in storage_interface and mobo.iloc[0].get('m2_slots', 0) > 0:
                    score += 0.4
                elif 'sata' in storage_interface and mobo.iloc[0].get('sata_ports', 0) > 0:
                    score += 0.4
                elif 'nvme' in storage_interface and mobo.iloc[0].get('m2_slots', 0) > 0:
                    score += 0.4
                
                # Check physical fit for larger drives
                if 'case' in current_build and '3.5' in storage_interface:
                    case_id = current_build['case']
                    case = self.components_df[self.components_df['id'] == case_id]
                    if not case.empty and case.iloc[0].get('drive_bays_3.5', 0) > 0:
                        score += 0.1
        
        # COOLING compatibility - NEW
        elif category == 'cooling':
            # Check socket compatibility with CPU
            if 'cpu' in current_build:
                cpu_id = current_build['cpu']
                cpu = self.components_df[self.components_df['id'] == cpu_id]
                if not cpu.empty:
                    cpu_socket = cpu.iloc[0].get('socket', '')
                    supported_sockets = component.get('supported_sockets', '')
                    
                    if cpu_socket and supported_sockets and cpu_socket in supported_sockets:
                        score += 0.5
            
            # Check case compatibility for radiator sizes
            if 'case' in current_build and component.get('type', '').lower() in ['liquid', 'aio']:
                case_id = current_build['case']
                case = self.components_df[self.components_df['id'] == case_id]
                if not case.empty:
                    radiator_size = component.get('radiator_size', '')
                    case_radiator_support = case.iloc[0].get('radiator_support', '')
                    
                    if radiator_size and case_radiator_support and radiator_size in case_radiator_support:
                        score += 0.3
            
            # Check clearance for air coolers
            if 'case' in current_build and component.get('type', '').lower() in ['air', 'cpu_cooler']:
                case_id = current_build['case']
                case = self.components_df[self.components_df['id'] == case_id]
                cooler_height = component.get('height_mm', 0)
                case_cpu_clearance = case.iloc[0].get('max_cpu_cooler_height', 0)
                
                if cooler_height and case_cpu_clearance and cooler_height <= case_cpu_clearance:
                    score += 0.2
        
        return min(score, 1.0)
    
    def _generate_recommendation_reason(self, component: pd.Series, score: float) -> str:
        """Generate human-readable reason for recommendation"""
        reasons = []
        
        if score >= 0.8:
            reasons.append("Highly similar features")
        elif score >= 0.6:
            reasons.append("Good feature match")
        else:
            reasons.append("Moderate similarity")
        
        # Add specific reasons based on component type
        if component['category'] == 'cpu':
            reasons.append(f"{component.get('cores', '')} cores")
        elif component['category'] == 'gpu':
            reasons.append(f"{component.get('vram', '')}GB VRAM")
        elif component['category'] == 'ram':
            reasons.append(f"{component.get('capacity', '')}GB")
        
        return ", ".join(reasons)
    
    def _generate_compatibility_notes(self, component: pd.Series, current_build: dict) -> List[str]:
        """Generate compatibility notes for recommendations - UPDATED VERSION"""
        notes = []
        category = component['category']
        
        # CPU compatibility notes
        if category == 'cpu' and 'motherboard' in current_build:
            mobo_id = current_build['motherboard']
            mobo = self.components_df[self.components_df['id'] == mobo_id]
            if not mobo.empty:
                if mobo.iloc[0]['socket'] == component.get('socket'):
                    notes.append(" Socket compatible with motherboard")
                else:
                    notes.append(" Socket mismatch with motherboard")
        
        # RAM compatibility notes
        elif category == 'ram' and 'motherboard' in current_build:
            mobo_id = current_build['motherboard']
            mobo = self.components_df[self.components_df['id'] == mobo_id]
            if not mobo.empty:
                if mobo.iloc[0]['memory_type'] == component.get('memory_type'):
                    notes.append(" Memory type compatible")
                else:
                    notes.append(" Memory type mismatch")
        
        # GPU compatibility notes
        elif category == 'gpu':
            if 'case' in current_build:
                case_id = current_build['case']
                case = self.components_df[self.components_df['id'] == case_id]
                if not case.empty:
                    if case.iloc[0]['max_gpu_length'] >= component.get('length_mm', 0):
                        notes.append(" Fits in selected case")
                    else:
                        notes.append(" May not fit in case")
            
            if 'psu' in current_build:
                psu_id = current_build['psu']
                psu = self.components_df[self.components_df['id'] == psu_id]
                if not psu.empty:
                    if psu.iloc[0]['wattage'] >= component.get('tdp', 0) + 100:
                        notes.append(" Sufficient PSU power")
                    else:
                        notes.append(" Check PSU wattage")
        
        # STORAGE compatibility notes - NEW
        elif category == 'storage' and 'motherboard' in current_build:
            mobo_id = current_build['motherboard']
            mobo = self.components_df[self.components_df['id'] == mobo_id]
            if not mobo.empty:
                storage_interface = component.get('interface', '').lower()
                
                if 'm.2' in storage_interface or 'nvme' in storage_interface:
                    if mobo.iloc[0].get('m2_slots', 0) > 0:
                        notes.append(" M.2 slot available on motherboard")
                    else:
                        notes.append(" No M.2 slots on motherboard")
                elif 'sata' in storage_interface:
                    if mobo.iloc[0].get('sata_ports', 0) > 0:
                        notes.append(" SATA ports available")
                    else:
                        notes.append(" No SATA ports available")
        
        # COOLING compatibility notes - NEW
        elif category == 'cooling':
            # Socket compatibility
            if 'cpu' in current_build:
                cpu_id = current_build['cpu']
                cpu = self.components_df[self.components_df['id'] == cpu_id]
                if not cpu.empty:
                    cpu_socket = cpu.iloc[0].get('socket', '')
                    supported_sockets = component.get('supported_sockets', '')
                    
                    if cpu_socket and supported_sockets:
                        if cpu_socket in supported_sockets:
                            notes.append(f" Compatible with {cpu_socket} socket")
                        else:
                            notes.append(f" Not compatible with {cpu_socket} socket")
            
            # Case compatibility for liquid cooling
            if 'case' in current_build and component.get('type', '').lower() in ['liquid', 'aio']:
                case_id = current_build['case']
                case = self.components_df[self.components_df['id'] == case_id]
                if not case.empty:
                    radiator_size = component.get('radiator_size', '')
                    case_radiator_support = case.iloc[0].get('radiator_support', '')
                    
                    if radiator_size and case_radiator_support:
                        if radiator_size in case_radiator_support:
                            notes.append(f" {radiator_size} radiator supported by case")
                        else:
                            notes.append(f" {radiator_size} radiator may not fit in case")
            
            # Clearance for air coolers
            if 'case' in current_build and component.get('type', '').lower() in ['air', 'cpu_cooler']:
                case_id = current_build['case']
                case = self.components_df[self.components_df['id'] == case_id]
                cooler_height = component.get('height_mm', 0)
                case_cpu_clearance = case.iloc[0].get('max_cpu_cooler_height', 0)
                
                if cooler_height and case_cpu_clearance:
                    if cooler_height <= case_cpu_clearance:
                        notes.append(f" Fits within case cooler clearance ({case_cpu_clearance}mm)")
                    else:
                        notes.append(f" May exceed case cooler clearance ({case_cpu_clearance}mm)")
        
        return notes
    
    def save_model(self, filepath: str):
        """Save trained model"""
        model_data = {
            'tfidf_vectorizer': self.tfidf_vectorizer,
            'tfidf_matrix': self.tfidf_matrix,
            'components_df': self.components_df,
            'similarity_matrix': self.similarity_matrix
        }
        
        with open(filepath, 'wb') as f:
            pickle.dump(model_data, f)
        
        logger.info(f" Model saved to {filepath}")
    
    def load_model(self, filepath: str):
        """Load trained model"""
        with open(filepath, 'rb') as f:
            model_data = pickle.load(f)
        
        self.tfidf_vectorizer = model_data['tfidf_vectorizer']
        self.tfidf_matrix = model_data['tfidf_matrix']
        self.components_df = model_data['components_df']
        self.similarity_matrix = model_data.get('similarity_matrix')
        
        logger.info(f" Model loaded from {filepath}")

def main():
    """Train and test the model"""
    logger.info(" Starting PC Recommendation Training...")
    
    trainer = PCRecommendationTrainer(db_path="assemble_db.db", datasets_path="./datasets")
    
    try:
        # Load data and train model
        components_df = trainer.load_and_combine_datasets()
        trainer.train_model(components_df)
        
        # Calculate similarity matrix
        similarity_matrix = trainer.calculate_similarity_matrix()
        
        # Save the trained model
        trainer.save_model("trained_recommendation_model.pkl")
        
        # Test 1: Similar components (STRICT MODE - only database components)
        logger.info("\n Testing similar components (STRICT MODE)...")
        similar_strict = trainer.get_similar_components(component_id=1, category='cpu', n_recommendations=3, strict=True)
        
        if similar_strict:
            for i, rec in enumerate(similar_strict, 1):
                status = " Available" if rec['in_database'] else " Not in database"
                logger.info(f"   {i}. {rec['model_name']} - Score: {rec['similarity_score']:.3f} - {status}")
        else:
            logger.warning("   No strict recommendations found!")
        
        # Test 2: Compatible components (STRICT MODE - only database components)
        logger.info("\n Testing compatible components (STRICT MODE)...")
        test_build = {'motherboard': 2, 'cpu': 1}
        compatible_strict = trainer.get_compatible_components(test_build, 'ram', 3, strict=True)
        
        if compatible_strict:
            for i, rec in enumerate(compatible_strict, 1):
                status = " Available" if rec['in_database'] else " Not in database"
                logger.info(f"   {i}. {rec['model_name']} - Compatibility: {rec['compatibility_score']:.3f} - {status}")
        else:
            logger.warning("   No strict compatible recommendations found!")
        
        # Test 3: Database-first approach
        logger.info("\n Testing database-first recommendations...")
        db_recommendations = trainer.get_recommendations_from_database(component_id=1, category='cpu', n_recommendations=3)
        
        if db_recommendations:
            for i, rec in enumerate(db_recommendations, 1):
                logger.info(f"   {i}. {rec['model_name']} - Score: {rec['similarity_score']:.3f} - Available in store")
        else:
            logger.warning("   No database-first recommendations found!")
        
        # Also show regular mode for comparison
        logger.info("\n Testing similar components (REGULAR MODE)...")
        similar_regular = trainer.get_similar_components(component_id=1, category='cpu', n_recommendations=3, strict=False)
        
        if similar_regular:
            for i, rec in enumerate(similar_regular, 1):
                status = " Available" if rec['in_database'] else " Not in database"
                logger.info(f"   {i}. {rec['model_name']} - Score: {rec['similarity_score']:.3f} - {status}")
        
        logger.info("\nTraining and testing completed successfully!")
        
    except Exception as e:
        logger.error(f"Error during training: {e}") 
        raise 

if __name__ == "__main__":
    main()
from flask import Flask, request, jsonify
from flask_cors import CORS
from train_recommendation_model import PCRecommendationTrainer
import os
import logging
import traceback
import base64
import sqlite3
import pandas as pd

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Global variables
trainer = PCRecommendationTrainer(db_path="assemble_db.db", datasets_path="./datasets")
similarity_matrix = None
components_df = None

def initialize_system():
    """Initialize the recommendation system with better error handling"""
    global trainer, similarity_matrix, components_df
    
    try:
        model_path = "trained_recommendation_model.pkl"
        
        if os.path.exists(model_path):
            logger.info("Loading pre-trained model...")
            trainer.load_model(model_path)
            components_df = trainer.components_df
            # Recalculate similarity matrix
            similarity_matrix = trainer.calculate_similarity_matrix()
            logger.info(f"Model loaded: {len(components_df)} components")
        else:
            logger.info("No pre-trained model found. Training new model...")
            components_df = trainer.load_and_combine_datasets()
            trainer.train_model(components_df)
            similarity_matrix = trainer.calculate_similarity_matrix()
            trainer.save_model(model_path)
            logger.info(f" Model trained: {len(components_df)} components")
        
        logger.info(" Recommendation system initialized successfully")
        
    except Exception as e:
        logger.error(f" Failed to initialize recommendation system: {e}")
        logger.error(traceback.format_exc())
        # Don't raise the exception, just log it so the server can still start
        components_df = None
        similarity_matrix = None

# Initialize the system when the app starts
initialize_system()

# ========== SYNC ENDPOINTS ==========
@app.route('/api/fix-dataset-ids', methods=['POST'])
def fix_dataset_ids_endpoint():
    """API endpoint to fix dataset IDs"""
    try:
        datasets = {
            'cpu_dataset.csv': 0,
            'gpu_dataset.csv': 100,
            'motherboard_dataset.csv': 200,
            'ram_dataset.csv': 300,
            'storage_dataset.csv': 400,
            'psu_dataset.csv': 500,
            'case_dataset.csv': 600,
            'cooling_dataset.csv': 700
        }
        
        results = []
        for filename, offset in datasets.items():
            file_path = f'./datasets/{filename}'
            if os.path.exists(file_path):
                df = pd.read_csv(file_path)
                new_ids = list(range(offset + 1, offset + 1 + len(df)))
                df['id'] = new_ids
                df.to_csv(file_path, index=False)
                results.append(f" {filename}: IDs {new_ids[0]}-{new_ids[-1]}")
            else:
                results.append(f" {filename} not found")
        
        return jsonify({
            'success': True,
            'message': 'Dataset IDs fixed successfully',
            'results': results
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/sync/database', methods=['POST'])
def sync_database():
    """Receive full database sync from Flutter app"""
    try:
        data = request.get_json()
        database_data = data.get('database_data')
        timestamp = data.get('timestamp')
        
        logger.info(f" Received database sync request at {timestamp}")
        
        if not database_data:
            return jsonify({'error': 'No database data provided'}), 400
        
        # Decode base64 database
        db_bytes = base64.b64decode(database_data)
        
        # Save to file (overwrite existing)
        with open('assemble_db.db', 'wb') as f:
            f.write(db_bytes)
        
        logger.info(" Database file updated")
        
        # Reload the recommendation system with new database
        initialize_system()
        
        logger.info(" Recommendation system reloaded with new database")
        return jsonify({'success': True, 'message': 'Database synced and system reloaded'})
        
    except Exception as e:
        logger.error(f"Database sync error: {e}")
        logger.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@app.route('/api/sync/component', methods=['POST'])
def sync_component():
    """Receive individual component sync from Flutter"""
    try:
        data = request.get_json()
        component = data.get('component')
        category = data.get('category')
        action = data.get('action')
        
        logger.info(f" Received component sync: {action} {category}")
        
        if not component or not category:
            return jsonify({'error': 'Component and category are required'}), 400
        
        component_id = None
        if action == 'add':
            # Add component to local database
            component_id = _add_component_to_database(component, category)
            
            # Update model with new data
            _update_model_with_new_component(component, category, component_id)
            
            logger.info(f"{category} component added and model updated")
        
        return jsonify({
            'success': True, 
            'message': f'{category} synced',
            'component_id': component_id
        })
        
    except Exception as e:
        logger.error(f" Component sync error: {e}")
        logger.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

def _add_component_to_database(component, category):
    """Add component to local SQLite database"""
    try:
        conn = sqlite3.connect('assemble_db.db')
        cursor = conn.cursor()
        
        # Map category to table name
        table_mapping = {
            'cpu': 'CPUtable',
            'gpu': 'GPUtable',
            'ram': 'RAMtable',
            'psu': 'PSUtable',
            'storage': 'storagetable',
            'motherboard': 'motherboardtable',
            'case': 'casetable',
            'cooling': 'coolingtable'
        }
        
        table_name = table_mapping.get(category)
        if not table_name:
            raise Exception(f"Unknown category: {category}")
        
        # Remove id if it's None (for auto-increment)
        component_data = component.copy()
        if component_data.get('id') is None:
            component_data.pop('id', None)
        
        # DEBUG: Print what we're trying to insert
        print(f" Inserting into {table_name}:")
        print(f"   Columns: {list(component_data.keys())}")
        print(f"   Values: {list(component_data.values())}")
        
        # Get the actual column names from the database table
        try:
            cursor.execute(f"PRAGMA table_info({table_name})")
            table_info = cursor.fetchall()
            actual_columns = [col[1] for col in table_info if col[1] != 'id']  # Skip id column
            print(f"   Actual columns in {table_name}: {actual_columns}")
            
            # Filter component_data to only include columns that exist in the table
            filtered_component_data = {}
            for key, value in component_data.items():
                if key in actual_columns:
                    filtered_component_data[key] = value
                else:
                    print(f"    Skipping column '{key}' - not in table")
            
            component_data = filtered_component_data
            
        except Exception as e:
            print(f"  Could not get table info: {e}")
            # Continue with original data if we can't get table info
        
        # Build insert query with filtered data
        if not component_data:
            raise Exception("No valid columns to insert after filtering")
            
        columns = ', '.join(component_data.keys())
        placeholders = ', '.join(['?' for _ in component_data])
        values = list(component_data.values())
        
        query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
        print(f"   Final query: {query}")
        print(f"   Final values: {values}")
        
        cursor.execute(query, values)
        
        # Get the inserted ID
        component_id = cursor.lastrowid
        
        conn.commit()
        conn.close()
        
        logger.info(f" Added {category} to database with ID: {component_id}")
        return component_id
        
    except Exception as e:
        logger.error(f"Error adding component to database: {e}")
        print(f" Detailed error: {traceback.format_exc()}")
        raise

def _update_model_with_new_component(component, category, component_id):
    """Update the recommendation model with new component - OPTIMIZED VERSION"""
    global components_df, similarity_matrix
    
    try:
        # Instead of retraining the entire model, just update the data
        # and let the next initialization handle it properly
        
        logger.info(f" Component {category} (ID: {component_id}) added to database")
        logger.info(" Model will be updated on next system restart or via full retrain")
        
        # For now, we'll just reload the system to ensure consistency
        initialize_system()
        
    except Exception as e:
        logger.error(f" Error updating model: {e}")
        logger.error(traceback.format_exc())
        raise

# ========== RECOMMENDATION ENDPOINTS ==========

@app.route('/', methods=['GET'])
def home():
    """Root endpoint"""
    return jsonify({
        'message': 'PC Component Recommendation API',
        'status': 'running',
        'endpoints': {
            'GET /': 'This message',
            'GET /health': 'Health check',
            'POST /similar': 'Get similar components',
            'POST /compatible': 'Get compatible components',
            'POST /api/sync/database': 'Sync full database',
            'POST /api/sync/component': 'Sync individual component',
            'POST /api/retrain': 'Force retrain model'
        }
    })

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    status = {
        'status': 'healthy',
        'message': 'PC Component Recommendation API',
        'components_loaded': len(components_df) if components_df is not None else 0,
        'model_loaded': components_df is not None,
        'similarity_matrix_loaded': similarity_matrix is not None,
        'sync_endpoints_available': True
    }
    return jsonify(status)

@app.route('/similar', methods=['POST'])
def recommend_similar():
    """
    Get similar components to a specific component
    Expected JSON: {"component_id": 1, "category": "cpu", "n_recommendations": 5, "strict": false}
    """
    try:
        data = request.get_json()
        logger.info(f" Received similar request: {data}")
        
        component_id = data.get('component_id')
        category = data.get('category')
        n_recommendations = data.get('n_recommendations', 5)
        strict_mode = data.get('strict', False)  # Add strict mode support
        
        if not component_id or not category:
            return jsonify({'error': 'component_id and category are required'}), 400
        
        recommendations = trainer.get_similar_components(
            component_id=component_id,
            category=category,
            n_recommendations=n_recommendations,
            strict=strict_mode  # Pass strict parameter
        )
        
        logger.info(f"Returning {len(recommendations)} similar recommendations (strict: {strict_mode})")
        
        return jsonify({
            'success': True,
            'component_id': component_id,
            'category': category,
            'strict_mode': strict_mode,
            'recommendations': recommendations
        })
        
    except Exception as e:
        logger.error(f" Error in similar recommendations: {e}")
        logger.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@app.route('/compatible', methods=['POST'])
def recommend_compatible():
    """
    Get compatible recommendations for current build
    Expected JSON: {"current_build": {"cpu": 1, "motherboard": 2}, "target_category": "ram", "n_recommendations": 5, "strict": false}
    Returns separate lists for database and dataset recommendations
    """
    try:
        data = request.get_json()
        logger.info(f" Received compatible request: {data}")
        
        current_build = data.get('current_build', {})
        target_category = data.get('target_category')
        n_recommendations = data.get('n_recommendations', 5)
        strict_mode = data.get('strict', False)
        
        if not target_category:
            return jsonify({'error': 'target_category is required'}), 400
        
        if strict_mode:
            # Strict mode: only database recommendations
            recommendations = trainer.get_compatible_components(
                current_build=current_build,
                target_category=target_category,
                n_recommendations=n_recommendations,
                strict=True
            )
            database_recommendations = recommendations
            dataset_recommendations = []
        else:
            # Non-strict mode: get both types separately
            all_recommendations = trainer.get_compatible_components(
                current_build=current_build,
                target_category=target_category,
                n_recommendations=n_recommendations,
                strict=False
            )
            
            # Separate database and dataset recommendations
            database_recommendations = [r for r in all_recommendations if r.get('in_database', False)]
            dataset_recommendations = [r for r in all_recommendations if not r.get('in_database', False)]
        
        logger.info(f" Returning {len(database_recommendations)} database and {len(dataset_recommendations)} dataset recommendations")
        
        return jsonify({
            'success': True,
            'target_category': target_category,
            'current_build': current_build,
            'strict_mode': strict_mode,
            'database_recommendations': database_recommendations,
            'dataset_recommendations': dataset_recommendations,
            'recommendations': database_recommendations + dataset_recommendations  # Keep for backward compatibility
        })
        
    except Exception as e:
        logger.error(f"Error in compatible recommendations: {e}")
        logger.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@app.route('/api/retrain', methods=['POST'])
def force_retrain():
    """Force retrain the recommendation model"""
    try:
        logger.info("Force retraining model...")
        initialize_system()
        
        return jsonify({
            'success': True,
            'message': 'Model retrained successfully',
            'components_count': len(components_df) if components_df else 0
        })
        
    except Exception as e:
        logger.error(f"Force retrain error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/test', methods=['GET'])
def test_endpoint():
    """Test endpoint to verify server is working"""
    return jsonify({
        'success': True,
        'message': 'Server is running with sync capabilities!',
        'endpoints': {
            'GET /': 'Home',
            'GET /health': 'Health check',
            'POST /similar': 'Get similar components',
            'POST /compatible': 'Get compatible components',
            'POST /api/sync/database': 'Sync full database',
            'POST /api/sync/component': 'Sync individual component',
            'POST /api/retrain': 'Force retrain model',
            'GET /test': 'Test endpoint'
        }
    })

# ========== SERVER STARTUP ==========
if __name__ == '__main__':
    import socket
    def get_ip():
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(('10.255.255.255', 1))
            IP = s.getsockname()[0]
        except:
            IP = '127.0.0.1'
        finally:
            s.close()
        return IP
    
    local_ip = get_ip()
    print(f"Server running!")
    print(f" On your phone use: http://{local_ip}:5000")
    print(f" On computer use: http://localhost:5000")
    print(f" Emulator use: http://10.0.2.2:5000")
    print("=" * 50)
    print("Available Endpoints:")
    print("  GET  / - Home")
    print("  GET  /health - Health check")
    print("  POST /similar - Get similar components")
    print("  POST /compatible - Get compatible components")
    print("  POST /api/sync/database - Sync full database")
    print("  POST /api/sync/component - Sync individual component")
    print("  POST /api/retrain - Force retrain model")
    print("  GET  /test - Test endpoint")
    print("=" * 50)
    print("Sync system: READY")
    print("Strict mode: SUPPORTED")
    print("Availability checking: ENABLED")
    
    app.run(host='0.0.0.0', port=5000, debug=False)
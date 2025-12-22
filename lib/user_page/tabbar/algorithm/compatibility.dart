// Add these to your existing models file

import 'package:assemblex/services/cpu_service.dart';
import 'package:assemblex/services/motherboard_service.dart';
import 'package:assemblex/services/psu_service.dart';
import 'package:assemblex/services/storage_service.dart';
import 'package:assemblex/services/case_service.dart';
import 'package:assemblex/services/gpu_service.dart';
import 'package:assemblex/services/ram_service.dart';
import 'package:assemblex/services/cooling_service.dart';


class CompatibilityResult {
  final bool isCompatible;
  final List<String> errors;
  final List<String> warnings;
  final double completionPercentage;
  final int score;

  CompatibilityResult({
    required this.isCompatible,
    required this.errors,
    required this.warnings,
    required this.completionPercentage,
    required this.score,
  });
}

class PCBuild {
  final CPU? cpu;
  final Motherboard? motherboard;
  final RAM? ram;
  final GPU? gpu;
  final Storage? storage;
  final PSU? psu;
  final Case? c;
  final Cooling? cooling;

  PCBuild({
    this.cpu,
    this.motherboard,
    this.ram,
    this.gpu,
    this.storage,
    this.psu,
    this.c,
    this.cooling,
  });

  int get selectedComponentsCount {
    int count = 0;
    if (cpu != null) count++;
    if (motherboard != null) count++;
    if (ram != null) count++;
    if (gpu != null) count++;
    if (storage != null) count++;
    if (psu != null) count++;
    if (c != null) count++;
    if (cooling != null) count++;
    return count;
  }
}
class CompatibilityChecker {
  static CompatibilityResult checkCompatibility(PCBuild build) {
    List<String> errors = [];
    List<String> warnings = [];
    int compatibilityScore = 100;

    // 1. CPU - Motherboard Compatibility (CRITICAL)
    if (build.cpu != null && build.motherboard != null) {
      if (build.cpu!.socket != build.motherboard!.socket) {
        errors.add(' CPU socket (${build.cpu!.socket}) does not match motherboard socket (${build.motherboard!.socket})');
        compatibilityScore -= 25;
      }
    } else if (build.cpu != null && build.motherboard == null) {
      warnings.add(' CPU selected but no motherboard chosen');
    }

    // 2. RAM - Motherboard Compatibility (CRITICAL)
    if (build.ram != null && build.motherboard != null) {
      if (build.ram!.memoryType != build.motherboard!.memoryType) {
        errors.add(' RAM type (${build.ram!.memoryType}) is not supported by motherboard (${build.motherboard!.memoryType})');
        compatibilityScore -= 20;
      }
      
      // Check RAM capacity
      if (build.motherboard!.maxMemory > 0 && build.ram!.capacity > build.motherboard!.maxMemory) {
        warnings.add(' RAM capacity (${build.ram!.capacity}GB) exceeds motherboard maximum (${build.motherboard!.maxMemory}GB)');
        compatibilityScore -= 5;
      }
    }

    // 3. GPU - Case Compatibility (CRITICAL)
    if (build.gpu != null && build.c != null) {
      if (build.gpu!.length > build.c!.maxGpuLength) {
        errors.add(' GPU length (${build.gpu!.length}mm) exceeds case maximum (${build.c!.maxGpuLength}mm)');
        compatibilityScore -= 15;
      }
    }

    // 4. Motherboard - Case Compatibility (CRITICAL)
    if (build.motherboard != null && build.c != null) {
      if (!_isMotherboardCompatibleWithCase(build.motherboard!, build.c!)) {
        errors.add(' Motherboard form factor (${build.motherboard!.formFactor}) is not supported by case');
        compatibilityScore -= 15;
      }
    }

    // 5. PSU Wattage Check (IMPORTANT)
    if (build.psu != null) {
      final totalPower = calculateTotalPowerConsumption(build);
      if (build.psu!.wattage < totalPower) {
        errors.add(' PSU wattage (${build.psu!.wattage}W) is insufficient for system (${totalPower}W)');
        compatibilityScore -= 20;
      } else if (build.psu!.wattage < totalPower * 1.2) {
        warnings.add(' PSU wattage is adequate but no headroom for upgrades (recommended: ${(totalPower * 1.2).round()}W)');
        compatibilityScore -= 5;
      }
    }

    // 6. Cooler - CPU Compatibility (IMPORTANT)
    if (build.cooling != null && build.cpu != null) {
      if (!_isCoolerCompatibleWithCPU(build.cooling!, build.cpu!)) {
        errors.add(' CPU cooler does not support CPU socket (${build.cpu!.socket})');
        compatibilityScore -= 10;
      }
    } else if (build.cpu != null && build.cooling == null) {
      warnings.add(' No CPU cooler selected - using stock cooler');
    }

    // 7. Check if GPU is needed
    if (build.cpu != null && build.gpu == null && build.cpu!.integratedGraphics == 0) {
      errors.add(' CPU has no integrated graphics - GPU is required');
      compatibilityScore -= 10;
    }

    // Calculate completion percentage
    final completionPercentage = (build.selectedComponentsCount / 8) * 100;

    return CompatibilityResult(
      isCompatible: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      completionPercentage: completionPercentage,
      score: compatibilityScore.clamp(0, 100),
    );
  }

  // Helper Methods
  static bool _isMotherboardCompatibleWithCase(Motherboard motherboard, Case c) {
    // Convert comma-separated string to list and check
    final moboFormFactor = motherboard.formFactor.trim().toUpperCase();
    final supportedFormFactors = c.formFactor
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .toList();

    print('Checking case compatibility -> Mobo: '
        '$moboFormFactor, Case: ${c.formFactor}, Supported: $supportedFormFactors');

    // Direct match or common naming variants like "ATX Mid Tower" vs "ATX"
    return supportedFormFactors.any((form) =>
        form == moboFormFactor ||
        form.contains(moboFormFactor) ||
        moboFormFactor.contains(form));
  }

  static bool _isCoolerCompatibleWithCPU(Cooling cooler, CPU cpu) {
    // Convert comma-separated string to list and check
    final supportedSockets = cooler.supportedSockets.split(',').map((e) => e.trim()).toList();
    return supportedSockets.contains(cpu.socket);
  }

  static int calculateTotalPowerConsumption(PCBuild build) {
    int totalPower = 0;
    
    if (build.cpu != null) totalPower += build.cpu!.tdp;
    if (build.gpu != null) totalPower += build.gpu!.tdp;
    if (build.ram != null) totalPower += 10; // Estimate for RAM
    if (build.storage != null) totalPower += 5; // Estimate for storage
    if (build.motherboard != null) totalPower += 50; // Estimate for motherboard
    if (build.cooling != null) totalPower += 10; // Estimate for cooling
    
    // Add 20% buffer for safety
    return (totalPower * 1.2).round();
  }

  // Component filtering methods for your pickers
  static Future<List<Motherboard>> getCompatibleMotherboards(CPU cpu) async {
    final allMotherboards = await MotherboardService.getAllMotherboards();
    return allMotherboards.where((mb) => mb.socket == cpu.socket).toList();
  }

  static Future<List<RAM>> getCompatibleRAM(Motherboard motherboard) async {
    final allRAM = await RAMService.getAllRAMs();
    return allRAM.where((ram) => ram.memoryType == motherboard.memoryType).toList();
  }

  static Future<List<Case>> getCompatibleCases(Motherboard motherboard) async {
    final allCases = await CaseService.getAllCases();
    return allCases.where((c) {
      final supportedFormFactors = c.formFactor.split(',').map((e) => e.trim()).toList();
      return supportedFormFactors.contains(motherboard.formFactor);
    }).toList();
  }

  static Future<List<Cooling>> getCompatibleCoolers(CPU cpu) async {
    final allCoolers = await CoolingService.getAllCoolings();
    return allCoolers.where((cooler) {
      final supportedSockets = cooler.supportedSockets.split(',').map((e) => e.trim()).toList();
      return supportedSockets.contains(cpu.socket);
    }).toList();
  }

  static Future<List<PSU>> getRecommendedPSUs(PCBuild build) async {
    final totalPower = calculateTotalPowerConsumption(build);
    final allPSUs = await PSUService.getAllPSUs();
    
    // Return PSUs with at least 20% more wattage than needed
    return allPSUs.where((psu) => psu.wattage >= totalPower * 1.2).toList();
  }
}
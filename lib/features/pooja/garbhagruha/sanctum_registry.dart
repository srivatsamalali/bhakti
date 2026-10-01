import 'garbhagruha_scene.dart';
import 'venkateshwara_scene.dart';
import 'chamundeshwari_scene.dart';
import 'ganesha_scene.dart';
import 'lakshmi_scene.dart';

/// Single source of truth for all Sanctum Environments in consistent order
final List<GarbhagruhaEnvironment> allSanctumEnvironments = [
  venkateshwaraEnvironment,  // Index 0: Lord Venkateshwara, Tirumala Hills
  chamundeshwariEnvironment, // Index 1: Chamundeshwari, Chamundi Hills Mysuru
  ganeshaEnvironment,        // Index 2: Southadka Open Ganapathi, Western Ghats
  lakshmiEnvironment,        // Index 3: Karveer Nivasini Mahalakshmi, Kolhapur
];

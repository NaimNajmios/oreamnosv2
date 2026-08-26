import os, re

def revert_viewmodel(path, class_name, provider_name):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove @riverpod and part
    content = re.sub(r"import 'package:riverpod_annotation/riverpod_annotation.dart';\n", "", content)
    content = re.sub(r"@riverpod\n", "", content)
    content = re.sub(r"part '.*\.g\.dart';\n", "", content)
    
    # Change class declaration
    content = re.sub(r"class " + class_name + r" extends _\$" + class_name, 
                     "import 'package:flutter/foundation.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\n\nfinal " + provider_name + " = ChangeNotifierProvider<" + class_name + ">((ref) => " + class_name + "());\n\nclass " + class_name + " extends ChangeNotifier", 
                     content)

    content = re.sub(r"@override\n\s*void build\(\)", class_name + "() { build(); }\n  void build()", content)

    # ref.notifyListeners() -> notifyListeners()
    content = content.replace("ref.notifyListeners()", "notifyListeners()")

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

revert_viewmodel('lib/ui/features/settings/view_models/settings_view_model.dart', 'SettingsViewModel', 'settingsViewModelProvider')
revert_viewmodel('lib/ui/features/generate/view_models/generate_view_model.dart', 'GenerateViewModel', 'generateViewModelProvider')
revert_viewmodel('lib/ui/features/card_generator/view_models/card_generator_view_model.dart', 'CardGeneratorViewModel', 'cardGeneratorViewModelProvider')

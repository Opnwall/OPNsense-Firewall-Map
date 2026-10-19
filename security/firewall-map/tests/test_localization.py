"""Plugin-owned UI strings retain placeholders and never mutate machine values."""
import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path

APP = Path(__file__).resolve().parents[1] / 'src/opnsense/mvc/app'
CATALOG = APP / 'models/OPNsense/FirewallMap/I18n/zh_CN.json'


class LocalizationTest(unittest.TestCase):
    def test_catalog_placeholders(self):
        for source, translated in json.loads(CATALOG.read_text()).items():
            self.assertEqual(sorted(re.findall(r'%s|\{\w+\}', source)),
                             sorted(re.findall(r'%s|\{\w+\}', translated)), source)

    def test_templates_use_plugin_scoped_translator(self):
        for view in (APP / 'views/OPNsense/FirewallMap').glob('*.volt'):
            self.assertNotRegex(view.read_text(), r'(?<!fw)\blang\._\(')
        source = (APP / 'models/OPNsense/FirewallMap/Translation.php').read_text()
        self.assertNotIn('textdomain(', source)

    @unittest.skipUnless(shutil.which('php'), 'PHP CLI not installed')
    def test_locale_fallback_and_machine_values(self):
        translator = APP / 'models/OPNsense/FirewallMap/Translation.php'
        script = '''require $argv[1];
$t = new OPNsense\\FirewallMap\\Translation('zh_CN.UTF-8');
$e = new OPNsense\\FirewallMap\\Translation('en_US.UTF-8');
$f = ['id'=>'All traffic','value'=>'All traffic','label'=>'All traffic',
      'options'=>['auto'=>['value'=>'Equal','selected'=>0]],'secret'=>'All traffic'];
echo json_encode([$t->translate('All traffic'),$e->translate('All traffic'),$t->form($f)]);'''
        result = json.loads(subprocess.check_output(['php', '-r', script, str(translator)]))
        self.assertEqual(result[0], '所有流量')
        self.assertEqual(result[1], 'All traffic')
        self.assertEqual(result[2]['label'], '所有流量')
        self.assertEqual(result[2]['id'], 'All traffic')
        self.assertEqual(result[2]['value'], 'All traffic')
        self.assertEqual(result[2]['secret'], 'All traffic')
        self.assertEqual(result[2]['options']['auto']['value'], '相同')

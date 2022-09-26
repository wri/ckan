import os
ckan_venv = os.environ.get('CKAN_VENV', '/usr/lib/ckan/venv')
activate_this = os.path.join(ckan_venv, 'bin/activate_this.py')
execfile(activate_this, dict(__file__=activate_this))

from paste.deploy import loadapp
config_filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ckan.ini')
from paste.script.util.logging_config import fileConfig
fileConfig(config_filepath)
application = loadapp('config:%s' % config_filepath)

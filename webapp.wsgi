import os
import sys
path = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0,path)
sys.stdout = sys.stderr
from webapp import app as application
from webapp import myapp
applicaton = myapp(os.path.join(path,"gazetteer.db"))

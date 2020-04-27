## PgAdmin 4 Installation Steps
```
sudo apt-get update

sudo apt-get install build-essential libssl-dev libffi-dev libgmp3-dev
virtualenv python-pip libpq-dev python-dev -y
```

### Create virtual environment
```
mkdir pgAdmin4
cd pgAdmin4
virtualenv pgAdmin4
```


### Activate virtual environment
```
cd pgAdmin4
source bin/activate
```

### Download pgAdmin 4
```
wget https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v2.1/pip/pgadmin4-
2.1-py2.py3-none-any.whl

pip install pgadmin4-2.1-py2.py3-none-any.whl
```


### Configure and run pgAdmin 4
```
nano lib/python2.7/site-packages/pgadmin4/config_local.py
```
Add the following content in config_local.py.
```
import os
DATA_DIR = os.path.realpath(os.path.expanduser(u'~/.pgadmin/'))
LOG_FILE = os.path.join(DATA_DIR, 'pgadmin4.log')
SQLITE_PATH = os.path.join(DATA_DIR, 'pgadmin4.db')
SESSION_DB_PATH = os.path.join(DATA_DIR, 'sessions')
STORAGE_DIR = os.path.join(DATA_DIR, 'storage')
SERVER_MODE = False
```

Now, use the following command to run pgAdmin.

```
python lib/python2.7/site-packages/pgadmin4/pgAdmin4.py
```
-Note: If any flask-htmlmin module error appears then run the following commands to install the module and then run the server.

```
pip install flask-htmlmin
python lib/python2.7/site-packages/pgadmin4/pgAdmin4.py
```

Now, access http://localhost:5050 from any browser. If all the steps are completed properly then the browser will display the following page.

- [Credits](https://linuxhint.com/install-pgadmin4-ubuntu/)

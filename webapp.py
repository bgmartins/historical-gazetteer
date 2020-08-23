#!/usr/bin/env python


import logging
import json
import datetime
import math
import optparse
import os
import re
import sys
import threading
import time
import webbrowser
from math import sin, cos, acos, radians
from collections import namedtuple, OrderedDict
from functools import wraps
from flask import jsonify
from flask import send_file
from export_linked_places import export_gazetteer_to_linked_places, create_csv_sql, export_gazetteer_to_shp_file, printer
from export_whos_on_first import export_to_whos_on_first
from getpass import getpass
import shapely

# Py3k compat.
if sys.version_info[0] == 3:
    binary_types = (bytes, bytearray)
    decode_handler = 'backslashreplace'
    numeric = (int, float)
    unicode_type = str
    from io import StringIO
else:
    binary_types = (buffer, bytes, bytearray)
    decode_handler = 'replace'
    numeric = (int, long, float)
    unicode_type = unicode
    from StringIO import StringIO

try:
    from flask import (
        Flask, abort, escape, flash, jsonify, make_response, Markup, redirect,
        render_template, request, session, url_for)
except ImportError:
    raise RuntimeError('Unable to import flask module. Install by running '
                       'pip install flask')

try:
    from pygments import formatters, highlight, lexers
except ImportError:
    import warnings
    warnings.warn('pygments library not found.', ImportWarning)
    syntax_highlight = lambda data: '<pre>%s</pre>' % data
else:
    def syntax_highlight(data):
        if not data:
            return ''
        lexer = lexers.get_lexer_by_name('sql')
        formatter = formatters.HtmlFormatter(linenos=False)
        return highlight(data, lexer, formatter)

try:
    from peewee import __version__
    peewee_version = tuple([int(p) for p in __version__.split('.')])
except ImportError:
    raise RuntimeError('Unable to import peewee module. Install by running '
                       'pip install peewee')
else:
    if peewee_version <= (2, 4, 2):
        raise RuntimeError('Peewee >= 2.4.3 is required. Found version %s. '
                           'Please update by running pip install --update '
                           'peewee' % __version__)

from peewee import *
from peewee import IndexMetadata
from playhouse.dataset import DataSet
from playhouse.migrate import migrate

CUR_DIR = os.path.realpath(os.path.dirname(__file__))
DEBUG = False
MAX_RESULT_SIZE = 1000
ROWS_PER_PAGE = 50
SECRET_KEY = 'sqlite-database-browser-0.1.0'

app = Flask(
    __name__,
    static_folder=os.path.join(CUR_DIR, 'static'),
    template_folder=os.path.join(CUR_DIR, 'templates'))
app.config.from_object(__name__)
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = False
dataset = None
migrator = None

#
# Database metadata objects.
#

TriggerMetadata = namedtuple('TriggerMetadata', ('name', 'sql'))

ViewMetadata = namedtuple('ViewMetadata', ('name', 'sql'))

#
# Database helpers.
#

class SqliteDataSet(DataSet):
    @property
    def filename(self):
        return os.path.realpath(dataset._database.database)

    @property
    def base_name(self):
        return os.path.basename(self.filename)

    @property
    def created(self):
        stat = os.stat(self.filename)
        return datetime.datetime.fromtimestamp(stat.st_ctime)

    @property
    def modified(self):
        stat = os.stat(self.filename)
        return datetime.datetime.fromtimestamp(stat.st_mtime)

    @property
    def size_on_disk(self):
        stat = os.stat(self.filename)
        return stat.st_size

    def get_indexes(self, table):
        return dataset._database.get_indexes(table)

    def get_all_indexes(self):
        cursor = self.query(
            'SELECT name, sql FROM sqlite_master '
            'WHERE type = ? ORDER BY name',
            ('index',))
        return [IndexMetadata(row[0], row[1], None, None, None)
                for row in cursor.fetchall()]

    def get_columns(self, table):
        return dataset._database.get_columns(table)

    def get_foreign_keys(self, table):
        return dataset._database.get_foreign_keys(table)

    def get_triggers(self, table):
        cursor = self.query(
            'SELECT name, sql FROM sqlite_master '
            'WHERE type = ? AND tbl_name = ?',
            ('trigger', table))
        return [TriggerMetadata(*row) for row in cursor.fetchall()]

    def get_all_triggers(self):
        cursor = self.query(
            'SELECT name, sql FROM sqlite_master '
            'WHERE type = ? ORDER BY name',
            ('trigger',))
        return [TriggerMetadata(*row) for row in cursor.fetchall()]

    def get_all_views(self):
        cursor = self.query(
            'SELECT name, sql FROM sqlite_master '
            'WHERE type = ? ORDER BY name',
            ('view',))
        return [ViewMetadata(*row) for row in cursor.fetchall()]

    def get_virtual_tables(self):
        cursor = self.query(
            'SELECT name FROM sqlite_master '
            'WHERE type = ? AND sql LIKE ? '
            'ORDER BY name',
            ('table', 'CREATE VIRTUAL TABLE%'))
        return set([row[0] for row in cursor.fetchall()])

    def get_corollary_virtual_tables(self):
        virtual_tables = self.get_virtual_tables()
        suffixes = ['content', 'docsize', 'segdir', 'segments', 'stat']
        return set(
            '%s_%s' % (virtual_table, suffix) for suffix in suffixes
            for virtual_table in virtual_tables)

#
# Flask views associated to gazetteer app.
#

@app.route('/main-page-export', methods=['POST'])
def main_page_export():
    query=get_request_data().get('query')
    export_format=get_request_data().get('format')
    
    if(export_format=="lp"):    
        filename="export_file.json"
        data = export_gazetteer_to_linked_places(query)
    elif(export_format=="csv"):
        sql = create_csv_sql(query)
        return export("g_feature", sql, export_format)
    elif(export_format=="shp"):
        filename="export_file.shp"
        data = export_gazetteer_to_shp_file(query)
        return send_file(filename,attachment_filename=filename, as_attachment=True)
    else:
        return
    response = make_response(data)
    response.headers['Content-Type'] = "text/javascript"
    response.headers['Content-Disposition'] = 'attachment; filename=%s' % (filename)
    response.headers['Expires'] = 0
    response.headers['Pragma'] = 'public'
    return response
    

@app.route('/linked-places/', methods=['GET', 'POST'])
def export_linked_places():
    flash("Please wait. The processing the data in the linked places format may take a while...")
    mimetype = 'text/javascript'
    data = export_gazetteer_to_linked_places(dataset.filename,"##")
    filename="export_lfp.json"
    try:
        os.remove(filename)
    except OSError:
        pass
    file_obj = open(filename, 'w', encoding='utf8')
    json.dump(data,file_obj)
    response_data=file_obj
    response = make_response(data)
    response.headers['Content-Type'] = 'text'
    response.headers['Content-Disposition'] = 'attachment; filename=%s' % (
        "export_lfp.json")
    response.headers['Expires'] = 0
    response.headers['Pragma'] = 'public'
    return response

@app.route('/pip/', methods=['GET', 'POST'])
def pip():
    id_string=get_request_data().get('id_string')
    id_list = id_string.split("##")
    try:
        response = []
        for feature_id in id_list:
            for r in dataset.query("SELECT DISTINCT name FROM g_feature_name WHERE feature_id=? and primary_display=1", (int(feature_id),)):
                aux = { "Id": int(feature_id), "Name": r[0], "Placetype": None }
                response.append(aux)
        return jsonify(response)
    except Exception as e: return jsonify({ "error": repr(e) })
    
@app.route('/gazetteer-data/', methods=['GET', 'POST'])
def gazetteer_data():
    data = {}#export_to_whos_on_first(dataset.filename)
    return jsonify(data)

@app.route('/gazetteer-id/', methods=['GET', 'POST'])
def gazetteer_id():
    data = export_gazetteer_to_linked_places(dataset.filename)
    return jsonify(data)

@app.route('/autocomplete/', methods=['GET', 'POST'])
def autocomplete():
    text= get_request_data().get('place')
    response = []
    queryString="SELECT DISTINCT name FROM g_feature_name WHERE name LIKE '" + text+ "%' LIMIT 5"
    for r in dataset.query(queryString):
        aux = r[0] 
        response.append(aux)
    return jsonify(json_list=response)

@app.route('/place-info/', methods=['GET', 'POST'])
def place_info():
    r_id = (get_request_data().get('input_place') or '').strip()
    if not r_id:
        return  render_template('login.html', results_visible='none', results={}, geoResults=[])
    id_list=[r_id]
    pop_up_list=[]
    r_name = dataset.query("SELECT name FROM g_feature_name WHERE feature_id= ? and primary_display=1 LIMIT 1", (r_id,)).fetchone()[0]
    pop_up_list.append(r_name)
    r_type = dataset.query("SELECT term FROM l_scheme_term WHERE scheme_term_id IN (SELECT classification_term_id FROM g_classification WHERE feature_id= ? LIMIT 1)", (r_id,)).fetchone()[0]
    
    time_period_id = dataset.query("select time_period_id from g_feature where feature_id = ?", (r_id,)).fetchone()[0]
    time_period_term = dataset.query("select time_period_name from g_time_period_to_period_name natural join l_time_period_name where time_period_id = ?", (time_period_id,)).fetchone()[0]
    raw_local_id= dataset.query("select location_id from g_location where feature_id=?", (r_id,)).fetchone()
    raw_geometry=None
    r_geometry=None
    if(raw_local_id!=None):
        local_id=raw_local_id[0]
        raw_geometry = dataset.query("select encoded_geometry from g_location_geometry where location_id=?",(local_id,)).fetchone()
    if(raw_geometry!=None):
        raw_geometry=raw_geometry[0]
    P = shapely.wkt.loads(raw_geometry).simplify(0.2, preserve_topology=False)
    MP = shapely.geometry.mapping(P)
    area=P.area
    MP["area"] = P.area
    
    name_id=dataset.query("select feature_name_id FROM g_feature_name WHERE feature_id= ? and primary_display=1 LIMIT 1",(r_id,)).fetchone()[0]
    source_id = dataset.query("select source_reference_id from g_name_to_link_info_reference where feature_name_id=?",(name_id,)).fetchone()[0]
    mnemonic = dataset.query("select source_mnemonic from g_source where source_reference_id=?",(source_id,)).fetchone()[0]
    source_desc = dataset.query("select citation from l_source_reference where source_reference_id=?",(source_id,)).fetchone()[0]
    
    r_alt_names = ""
    r_related_features=[]
    for alt in dataset.query("SELECT name FROM g_feature_name WHERE feature_id= ? and primary_display=0 LIMIT 1",(r_id,)).fetchall():
        r_alt_names = r_alt_names + alt[0] + ", "
    for related in dataset.query("SELECT related_name, related_feature_feature_id, related_type_term_id from g_related_feature where feature_id = ?", (r_id,)).fetchall():
        related_type_term = dataset.query("SELECT term FROM l_scheme_term WHERE scheme_term_id=?",(related[2],)).fetchone()[0]
        r_related_features.append([related[0],related[1],related_type_term])
    if(len(r_alt_names)==0):
        r_alt_names=None
    if(len(r_related_features)==0):
        r_related_features=[]   
    
    results={}
    results['primary_name']=r_name
    results['alt_names']=r_alt_names
    results['type']=r_type
    results['time_period_term']=time_period_term
    results['time_period_span']=""
    results['geometry']=MP
    results['source']=source_desc
    results['mnemonic']=mnemonic
    results['related_features']=r_related_features
    results['bbox']=P.bounds
    
    geoFlaskResults=export_to_whos_on_first('gazetteer.db',id_list,pop_up_list)
    
    return render_template('place_info.html', 
                           results=results,
                           geoResults=geoFlaskResults
                           )

@app.route('/gazetteer-search/', methods=['GET', 'POST'])
def gazetteer_search():
    text = (get_request_data().get('input_place') or '').strip()
    if not text:
        return  render_template('login.html', results_visible='none', results={}, geoResults=[])
    id_query="SELECT feature_id from g_feature_name WHERE primary_display=1 and name LIKE '%"+text+"%' LIMIT 15"
    record_list=dataset.query(id_query).fetchall()
    id_list=[]
    pop_up_list=[]
    for fid in record_list:
        id_list.append(fid[0])
    for r_id in id_list:
        place_info=[]
        place_info.append(r_id)
        r_name = dataset.query("SELECT name FROM g_feature_name WHERE feature_id= ? and primary_display=1 LIMIT 1", (r_id,)).fetchone()[0]
        pop_up_list.append(r_name)
        place_info.append(r_name)
    
  
    geoFlaskResults=export_to_whos_on_first('gazetteer.db',id_list,pop_up_list)
    
    return render_template('login.html', 
                           geoResults=geoFlaskResults
                           )

#
# Flask views associated to SQL browser.
#
    
@app.route('/login/', methods=['GET', 'POST'])
def login():
    session['authorized'] = True
    if request.method == 'POST':
        if request.form.get('password') == app.config['PASSWORD']:
            return redirect(url_for('index'))
    return render_template('login.html', results_visible='none', results={}, geoResults=[])

@app.route('/logout/', methods=['GET'])
def logout():
    session.pop('authorized', None)
    return redirect(url_for('login'))

def install_auth_handler(password):
    app.config['PASSWORD'] = password

@app.before_request
def check_password():
    if not session.get('authorized') and request.path != '/login/' and \
       not request.path.startswith(('/static/', '/favicon')):
        session['next_url'] = request.base_url
        return redirect(url_for('login'))

@app.route('/', methods=['GET','POST'])
def index():
    return render_template('index.html')

def require_table(fn):
    @wraps(fn)
    def inner(table, *args, **kwargs):
        if table not in dataset.tables:
            abort(404)
        return fn(table, *args, **kwargs)
    return inner

@app.route('/create-table/', methods=['POST'])
def table_create():
    table = (request.form.get('table_name') or '').strip()
    if not table:
        flash('Table name is required.', 'danger')
        return redirect(request.form.get('redirect') or url_for('index'))

    dataset[table]
    return redirect(url_for('table_import', table=table))

@app.route('/<table>/')
@require_table
def table_structure(table):
    ds_table = dataset[table]
    model_class = ds_table.model_class

    table_sql = dataset.query(
        'SELECT sql FROM sqlite_master WHERE tbl_name = ? AND type = ?',
        [table, 'table']).fetchone()[0]

    return render_template(
        'table_structure.html',
        columns=dataset.get_columns(table),
        ds_table=ds_table,
        foreign_keys=dataset.get_foreign_keys(table),
        indexes=dataset.get_indexes(table),
        model_class=model_class,
        table=table,
        table_sql=table_sql,
        triggers=dataset.get_triggers(table))

def get_request_data():
    if request.method == 'POST':
        return request.form
    return request.args

@app.route('/<table>/add-column/', methods=['GET', 'POST'])
@require_table
def add_column(table):
    column_mapping = OrderedDict((
        ('VARCHAR', CharField),
        ('TEXT', TextField),
        ('INTEGER', IntegerField),
        ('REAL', FloatField),
        ('BOOL', BooleanField),
        ('BLOB', BlobField),
        ('DATETIME', DateTimeField),
        ('DATE', DateField),
        ('TIME', TimeField),
        ('DECIMAL', DecimalField)))

    request_data = get_request_data()
    col_type = request_data.get('type')
    name = request_data.get('name', '')

    if request.method == 'POST':
        if name and col_type in column_mapping:
            migrate(
                migrator.add_column(
                    table,
                    name,
                    column_mapping[col_type](null=True)))
            flash('Column "%s" was added successfully!' % name, 'success')
            return redirect(url_for('table_structure', table=table))
        else:
            flash('Name and column type are required.', 'danger')

    return render_template(
        'add_column.html',
        col_type=col_type,
        column_mapping=column_mapping,
        name=name,
        table=table)

@app.route('/<table>/drop-column/', methods=['GET', 'POST'])
@require_table
def drop_column(table):
    request_data = get_request_data()
    name = request_data.get('name', '')
    columns = dataset.get_columns(table)
    column_names = [column.name for column in columns]

    if request.method == 'POST':
        if name in column_names:
            migrate(migrator.drop_column(table, name))
            flash('Column "%s" was dropped successfully!' % name, 'success')
            return redirect(url_for('table_structure', table=table))
        else:
            flash('Name is required.', 'danger')

    return render_template(
        'drop_column.html',
        columns=columns,
        column_names=column_names,
        name=name,
        table=table)

@app.route('/<table>/rename-column/', methods=['GET', 'POST'])
@require_table
def rename_column(table):
    request_data = get_request_data()
    rename = request_data.get('rename', '')
    rename_to = request_data.get('rename_to', '')

    columns = dataset.get_columns(table)
    column_names = [column.name for column in columns]

    if request.method == 'POST':
        if (rename in column_names) and (rename_to not in column_names):
            migrate(migrator.rename_column(table, rename, rename_to))
            flash('Column "%s" was renamed successfully!' % rename, 'success')
            return redirect(url_for('table_structure', table=table))
        else:
            flash('Column name is required and cannot conflict with an '
                  'existing column\'s name.', 'danger')

    return render_template(
        'rename_column.html',
        columns=columns,
        column_names=column_names,
        rename=rename,
        rename_to=rename_to,
        table=table)

@app.route('/<table>/add-index/', methods=['GET', 'POST'])
@require_table
def add_index(table):
    request_data = get_request_data()
    indexed_columns = request_data.getlist('indexed_columns')
    unique = bool(request_data.get('unique'))

    columns = dataset.get_columns(table)

    if request.method == 'POST':
        if indexed_columns:
            migrate(
                migrator.add_index(
                    table,
                    indexed_columns,
                    unique))
            flash('Index created successfully.', 'success')
            return redirect(url_for('table_structure', table=table))
        else:
            flash('One or more columns must be selected.', 'danger')

    return render_template(
        'add_index.html',
        columns=columns,
        indexed_columns=indexed_columns,
        table=table,
        unique=unique)

@app.route('/<table>/drop-index/', methods=['GET', 'POST'])
@require_table
def drop_index(table):
    request_data = get_request_data()
    name = request_data.get('name', '')
    indexes = dataset.get_indexes(table)
    index_names = [index.name for index in indexes]

    if request.method == 'POST':
        if name in index_names:
            migrate(migrator.drop_index(table, name))
            flash('Index "%s" was dropped successfully!' % name, 'success')
            return redirect(url_for('table_structure', table=table))
        else:
            flash('Index name is required.', 'danger')

    return render_template(
        'drop_index.html',
        indexes=indexes,
        index_names=index_names,
        name=name,
        table=table)

@app.route('/<table>/drop-trigger/', methods=['GET', 'POST'])
@require_table
def drop_trigger(table):
    request_data = get_request_data()
    name = request_data.get('name', '')
    triggers = dataset.get_triggers(table)
    trigger_names = [trigger.name for trigger in triggers]

    if request.method == 'POST':
        if name in trigger_names:
            dataset.query('DROP TRIGGER "%s";' % name)
            flash('Trigger "%s" was dropped successfully!' % name, 'success')
            return redirect(url_for('table_structure', table=table))
        else:
            flash('Trigger name is required.', 'danger')

    return render_template(
        'drop_trigger.html',
        triggers=triggers,
        trigger_names=trigger_names,
        name=name,
        table=table)

@app.route('/<table>/content/')
@require_table
def table_content(table):
    page_number = request.args.get('page') or ''
    page_number = int(page_number) if page_number.isdigit() else 1

    ds_table = dataset[table]
    total_rows = ds_table.all().count()
    rows_per_page = app.config['ROWS_PER_PAGE']
    total_pages = int(math.ceil(total_rows / float(rows_per_page)))
    # Restrict bounds.
    page_number = min(page_number, total_pages)
    page_number = max(page_number, 1)

    previous_page = page_number - 1 if page_number > 1 else None
    next_page = page_number + 1 if page_number < total_pages else None

    query = ds_table.all().paginate(page_number, rows_per_page)

    ordering = request.args.get('ordering')
    if ordering:
        field = ds_table.model_class._meta.columns[ordering.lstrip('-')]
        if ordering.startswith('-'):
            field = field.desc()
        query = query.order_by(field)

    field_names = ds_table.columns
    model_meta = ds_table.model_class._meta
    try:
        fields = model_meta.sorted_fields
    except AttributeError:
        fields = model_meta.get_fields()
    if peewee_version >= (3, 0, 0):
        columns = [field.column_name for field in fields]
    else:
        columns = [field.db_column for field in fields]

    table_sql = dataset.query(
        'SELECT sql FROM sqlite_master WHERE tbl_name = ? AND type = ?',
        [table, 'table']).fetchone()[0]

    return render_template(
        'table_content.html',
        columns=columns,
        ds_table=ds_table,
        field_names=field_names,
        next_page=next_page,
        ordering=ordering,
        page=page_number,
        previous_page=previous_page,
        query=query,
        table=table,
        total_pages=total_pages,
        total_rows=total_rows)

@app.route('/<table>/query/', methods=['GET', 'POST'])
@require_table
def table_query(table):
    data = []
    data_description = error = row_count = sql = None

    if request.method == 'POST':
        sql = request.form['sql']
        if 'export_json' in request.form:
            return export(table, sql, 'json')
        elif 'export_csv' in request.form:
            return export(table, sql, 'csv')
        try:
            cursor = dataset.query(sql)
        except Exception as exc:
            error = str(exc)
        else:
            data = cursor.fetchall()[:app.config['MAX_RESULT_SIZE']]
            data_description = cursor.description
            row_count = cursor.rowcount
    else:
        if request.args.get('sql'):
            sql = request.args.get('sql')
        else:
            sql = 'SELECT *\nFROM "%s"' % (table)

    table_sql = dataset.query(
        'SELECT sql FROM sqlite_master WHERE tbl_name = ? AND type = ?',
        [table, 'table']).fetchone()[0]

    return render_template(
        'table_query.html',
        data=data,
        data_description=data_description,
        error=error,
        query_images=get_query_images(),
        row_count=row_count,
        sql=sql,
        table=table,
        table_sql=table_sql)

@app.route('/table-definition/', methods=['POST'])
def set_table_definition_preference():
    key = 'show'
    show = False
    if request.form.get(key):
        session[key] = show = True
    elif key in request.session:
        del request.session[key]
    return jsonify({key: show})

def export(table, sql, export_format):
    model_class = dataset[table].model_class
    query = model_class.raw(sql).dicts()
    buf = StringIO()
    if export_format == 'json':
        kwargs = {'indent': 2}
        filename = '%s-export.json' % table
        mimetype = 'text/javascript'
    elif export_format == 'csv':
        kwargs = {}
        filename = '%s-export.csv' % table
        mimetype = 'text/csv'
        
    dataset.freeze(query, export_format, file_obj=buf, **kwargs)

    response_data = buf.getvalue()
    response = make_response(response_data)
    response.headers['Content-Length'] = len(response_data)
    response.headers['Content-Type'] = mimetype
    response.headers['Content-Disposition'] = 'attachment; filename=%s' % (
        filename)
    response.headers['Expires'] = 0
    response.headers['Pragma'] = 'public'
    return response

@app.route('/<table>/import/', methods=['GET', 'POST'])
@require_table
def table_import(table):
    count = None
    request_data = get_request_data()
    strict = bool(request_data.get('strict'))

    if request.method == 'POST':
        file_obj = request.files.get('file')
        if not file_obj:
            flash('Please select an import file.', 'danger')
        elif not file_obj.filename.lower().endswith(('.csv', '.json')):
            flash('Unsupported file-type. Must be a .json or .csv file.',
                  'danger')
        else:
            if file_obj.filename.lower().endswith('.json'):
                format = 'json'
            else:
                format = 'csv'
            try:
                with dataset.transaction():
                    count = dataset.thaw(
                        table,
                        format=format,
                        file_obj=file_obj.stream,
                        strict=strict)
            except Exception as exc:
                flash('Error importing file: %s' % exc, 'danger')
            else:
                flash(
                    'Successfully imported %s objects from %s.' % (
                        count, file_obj.filename),
                    'success')
                return redirect(url_for('table_content', table=table))

    return render_template(
        'table_import.html',
        count=count,
        strict=strict,
        table=table)

@app.route('/<table>/drop/', methods=['GET', 'POST'])
@require_table
def drop_table(table):
    if request.method == 'POST':
        model_class = dataset[table].model_class
        model_class.drop_table()
        flash('Table "%s" dropped successfully.' % table, 'success')
        return redirect(url_for('index'))

    return render_template('drop_table.html', table=table)

@app.template_filter('value_filter')
def value_filter(value, max_length=50):
    if isinstance(value, numeric):
        return value

    if isinstance(value, binary_types):
        if not isinstance(value, (bytes, bytearray)):
            value = bytes(value)  # Handle `buffer` type.
        value = value.decode('utf-8', decode_handler)
    if isinstance(value, unicode_type):
        value = escape(value)
        if len(value) > max_length:
            return ('<span class="truncated">%s</span> '
                    '<span class="full" style="display:none;">%s</span>'
                    '<a class="toggle-value" href="#">...</a>') % (
                        value[:max_length],
                        value)
    return value

column_re = re.compile('(.+?)\((.+)\)', re.S)
column_split_re = re.compile(r'(?:[^,(]|\([^)]*\))+')

def _format_create_table(sql):
    create_table, column_list = column_re.search(sql).groups()
    columns = ['  %s' % column.strip()
               for column in column_split_re.findall(column_list)
               if column.strip()]
    return '%s (\n%s\n)' % (
        create_table,
        ',\n'.join(columns))

@app.template_filter()
def format_create_table(sql):
    try:
        return _format_create_table(sql)
    except:
        return sql

@app.template_filter('highlight')
def highlight_filter(data):
    return Markup(syntax_highlight(data))

def get_query_images():
    accum = []
    image_dir = os.path.join(app.static_folder, 'img')
    if not os.path.exists(image_dir):
        return accum
    for filename in sorted(os.listdir(image_dir)):
        basename = os.path.splitext(os.path.basename(filename))[0]
        parts = basename.split('-')
        accum.append((parts, 'img/' + filename))
    return accum

#
# Flask application helpers.
#

@app.context_processor
def _general():
    return {
            'dataset': dataset,
            'login_required': bool(app.config.get('PASSWORD'))
    }

@app.context_processor
def _now():
    return {'now': datetime.datetime.now()}

@app.before_request
def _connect_db():
    dataset.connect()

@app.teardown_request
def _close_db(exc):
    if not dataset._database.is_closed():
        dataset.close()

#
# Script options.
#

def get_option_parser():
    parser = optparse.OptionParser()
    parser.add_option(
        '-p',
        '--port',
        default=8080,
        help='Port for web interface, default=8080',
        type='int')
    parser.add_option(
        '-H',
        '--host',
        default='127.0.0.1',
        help='Host for web interface, default=127.0.0.1')
    parser.add_option(
        '-d',
        '--debug',
        action='store_true',
        help='Run server in debug mode')
    parser.add_option(
        '-x',
        '--no-browser',
        action='store_false',
        default=True,
        dest='browser',
        help='Do not automatically open browser page.')
    parser.add_option(
        '-P',
        '--password',
        default=True,
        action='store_true',
        dest='prompt_password',
        help='Prompt for password to access database browser.')
    parser.add_option(
        '-r',
        '--read-only',
        action='store_true',
        default=True,
        dest='read_only',
        help='Open database in read-only mode.')
    parser.add_option(
        '-u',
        '--url-prefix',
        dest='url_prefix',
        help='URL prefix for application.')
    return parser

def die(msg, exit_code=1):
    sys.stderr.write('%s\n' % msg)
    sys.stderr.flush()
    sys.exit(exit_code)

def open_browser_tab(host, port):
    url = 'http://%s:%s/' % (host, port)

    def _open_tab(url):
        time.sleep(1.5)
        webbrowser.open_new_tab(url)

    thread = threading.Thread(target=_open_tab, args=(url,))
    thread.daemon = True
    thread.start()

def myapp(filename, read_only=False, password=None, url_prefix=None):
    global dataset
    global migrator

    if password:
        install_auth_handler(password)

    if read_only:
        if sys.version_info < (3, 4, 0):
            die('Python 3.4.0 or newer is required for read-only access.')
        if peewee_version < (3, 5, 1):
            die('Peewee 3.5.1 or newer is required for read-only access.')
        db = SqliteDatabase('%s' % filename, uri=True)
        try:
            db.connect()
        except OperationalError:
            die('Unable to open database file in read-only mode. Ensure that '
                'the database exists in order to use read-only mode.')
        db.close()
        dataset = SqliteDataSet(db, bare_fields=True)
    else:
        dataset = SqliteDataSet('sqlite:///%s' % filename, bare_fields=True)

    if url_prefix:
        app.wsgi_app = PrefixMiddleware(app.wsgi_app, prefix=url_prefix)

    migrator = dataset._migrator
    dataset.close()
    return app

def main():
    # This function exists to act as a console script entry-point.
    global db_file
    parser = get_option_parser()
    options, args = parser.parse_args()
    if not args: args = [ "gazetteer.db" ]
    password = None
    if options.prompt_password:
        if os.environ.get('SQLITE_WEB_PASSWORD'):
            password = os.environ['SQLITE_WEB_PASSWORD']
        else:
            while True:
                password = getpass('Enter password: ')
                password_confirm = getpass('Confirm password: ')
                if password != password_confirm:
                    print('Passwords did not match!')
                else:
                    break
    db_file = args[0]
    app = myapp(db_file, options.read_only, password,  options.url_prefix)
    if options.browser: open_browser_tab(options.host, options.port)
    # print(app.url_map)
    app.run(host=options.host, port=options.port, debug=options.debug)

if __name__ == '__main__':
    main()

import json
import string
from collections import defaultdict
from collections import OrderedDict
import numpy as np
import re

import sys
from langdetect import detect
from dateutil.parser import parse
import math

import operator
import time

import sqlite3

start_time = time.time()

fields = set()
datatype = dict()
field_count = dict()
field_blank = defaultdict()

field_value_count = dict()
field_token_len = dict()
field_punctuation_count = dict()

field_token_numeric_count = dict()
field_token_alpha_numeric_count = dict()

num_integer = dict()
num_decimal = dict()

field_value_numeric = dict()
field_value_len = dict()
field_token_count = dict()

field_language = dict()
topk = 15
include_punctuation = set(string.punctuation)

def is_Integer_Number_Ext(s):
    # return any(char.isdigit() for char in inputString)
    try:
        int(s)
        return True
    except:
        try:
            int(convertAlphatoNum(s))
            return True
        except:
            return False


def is_Decimal_Number_Ext(s):
    try:
        float(s)
        return True
    except:
        try:
            float(convertAlphatoNum(s))
            return True
        except:
            return False


def is_Integer_Number(s):
    # return any(char.isdigit() for char in inputString)
    try:
        int(s)
        return True
    except:
        return False


def is_Decimal_Number(s):
    try:
        float(s)
        return True
    except:
        return False


def getDecimal(s):
    try:
        return float(s)
    except:
        try:
            return float(convertAlphatoNum(s))
        except:
            return 0.0


def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description): d[col[0]] = row[idx]
    return d

def readjson(filename):
    with open(filename) as data_file:
        data = json.load(data_file)
    return data


def is_date(string):
    try:
        parse(string)
        return True
    except ValueError:
        return False


def item_generator(json_input, key=None, path="$"):
    if json_input is None:
        return
    if isinstance(json_input, dict):
        for k, v in json_input.iteritems():
            for child_val in item_generator(v, k, path + "[" + k + "]"):
                yield child_val
    elif isinstance(json_input, list):
        for item in json_input:
            for item_val in item_generator(item, "", path):
                yield item_val
    else:
        try:
            yield (path.strip('.'), str(json_input))
        except:
            yield (path.strip('.'), json_input.encode('utf-8'))
            pass


def getType(k, v):
    boolean_list = ['true', 'false']
    if v:
        if is_date(v):
            return "Date"
        if v.lower() in boolean_list:
            return 'Boolean'

        _type = type(v)
        if _type is int or _type is long:
            return "Integer"
        if _type is float:
            return "Decimal"
        if _type is str:
            return "String"

        return type(v)
    return None

def convertAlphatoNum(input):
    non_decimal = re.compile(r'[^\d.\s\w]+')
    return non_decimal.sub(' ', input)

def profile_data_wrapper(inputFile):
    input = {}
    try:
        connection = sqlite3.connect(inputFile)
        connection.row_factory = dict_factory
        cursor = connection.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = cursor.fetchall()
        for table_name in tables:
            conn = sqlite3.connect(inputFile)
            conn.row_factory = dict_factory
            cur1 = conn.cursor()		 
            cur1.execute("SELECT * FROM "+table_name['name'])		 
            results = cur1.fetchall()
            aux = json.loads(format(results).replace(" u'", "'").replace("'", "\""))
            input = dict(input.items() + aux.items())
            connection.close()
    except: input = readjson(inputFile)
    for k, v in item_generator(input):
        try:
            v = v.lower()
        except:
            print("Error in lower case...passing")
            pass
        # print k + "-->" + v

        # adding in the list of fields
        fields.add(k)

        #detecting language
        try:
            language = detect(v)
            if k not in field_language:
                field_language[k] = dict()
            if language in field_language[k]:
                field_language[k][language] += 1
            else:
                field_language[k][language] = 1
        except Exception as e:
            language = "en"
            pass


        #numeric field values
        if is_Integer_Number_Ext(v) or is_Decimal_Number_Ext(v):
            if not math.isnan(getDecimal(v)):
                if k not in field_value_numeric:
                    field_value_numeric[k] = []
                field_value_numeric[k].append(getDecimal(v))

        # field containing any integer
        if is_Integer_Number_Ext(v):
            if k in num_integer:
                num_integer[k] += 1
            else:
                num_integer[k] = 1

        # field for decimal
        elif is_Decimal_Number_Ext(v):
            if k in num_decimal:
                num_decimal[k] += 1
            else:
                num_decimal[k] = 1

        # updating the count of the field
        if k in field_count:
            field_count[k] += 1
        else:
            field_count[k] = 1

        # getting the datatype
        type = getType(k, v)
        if k not in datatype:
            datatype[k] = set()

        if type:
            datatype[k].add(type)

        # blank field
        if v is None or v.strip() is "":
            if k in field_blank:
                field_blank[k] += 1
            else:
                field_blank[k] = 1

        # count of each value
        if k not in field_value_count:
            field_value_count[k] = dict()

        if v in field_value_count[k]:
            field_value_count[k][v] += 1
        else:
            field_value_count[k][v] = 1

        #length of each word
        if k not in field_value_len:
            field_value_len[k] = []
        field_value_len[k].append(len(v))

        # count of each token
        tokens = v.split()
        #tokens = nltk.word_tokenize(v.decode('utf-8'))
        #print tokens
        #count of tokens
        if k not in field_token_len:
            field_token_len[k] = []
        field_token_len[k].append(len(tokens))

        for t in tokens:
            #if t in listofstopwords or t in include_punctuation:
            #    continue
            if k not in field_token_count:
                field_token_count[k] = dict()

            if t in field_token_count[k]:
                field_token_count[k][t] += 1
            else:
                field_token_count[k][t] = 1

            #numeric tokens count
            if is_Integer_Number(t) or is_Decimal_Number(t):
                if k not in field_token_numeric_count:
                    field_token_numeric_count[k] = dict()

                if t in field_token_numeric_count[k]:
                    field_token_numeric_count[k][t] += 1
                else:
                    field_token_numeric_count[k][t] = 1

                    # alphnumeic
            if t.isalnum():
                if k not in field_token_alpha_numeric_count:
                    field_token_alpha_numeric_count[k] = dict()

                if t in field_token_alpha_numeric_count[k]:
                    field_token_alpha_numeric_count[k][t] += 1
                else:
                    field_token_alpha_numeric_count[k][t] = 1

        # punctuations
        if k not in field_punctuation_count:
            field_punctuation_count[k] = dict()
        for ch in v:
            if ch in include_punctuation:
                if ch in field_punctuation_count[k]:
                    field_punctuation_count[k][ch] += 1
                else:
                    field_punctuation_count[k][ch] = 1

def profile_data(inputFile, outputFile, top_frequent=20):
    topk = top_frequent
    # process input file into required data structure.
    profile_data_wrapper(inputFile)
    res = dict()
    # processing the datastruture according to the reqd output json structure.
    for field in fields:
        curr_rec = {}
        try:
            # print "Field is " + field + " Count is " + str(field_count[field]) + " type is " + str(datatype[field])

            # curr_rec["field"] = str(field)
            curr_rec["field_count"] = field_count[field]
            curr_rec['type'] = []

            curr_rec['length'] = dict()
            curr_rec['frequent-entries'] = dict()

            if field in num_integer:
                curr_rec['length']["num_integer"] = num_integer[field]
            if field in num_decimal:
                curr_rec['length']["num_decimal"] = num_decimal[field]

            count_distinct_values = 0
            count_distinct_tokens = 0

            if field in datatype:
                for dt in datatype[field]:
                    curr_rec['type'].append(dt)
            if field in field_blank:
                curr_rec["num_blank"] = field_blank[field]
            else:
                curr_rec["num_blank"] = 0

            curr_rec["frequent-entries"]["most_common_values"] = dict()
            if field in field_value_count:
                dict_vals = field_value_count[field]
                sorted_dict_vals = sorted(dict_vals.items(), key=operator.itemgetter(1), reverse=True)
                countNonOne = 0
                for k, v in sorted_dict_vals:
                    if v == 1:
                        count_distinct_values = len(sorted_dict_vals) - countNonOne
                        break
                    countNonOne += 1
                # print sorted_dict_vals
                temp_dict = OrderedDict()
                for k, v in sorted_dict_vals[:topk]:
                    temp_dict[k] = v

                curr_rec["frequent-entries"]["most_common_values"] = temp_dict
                curr_rec["length"]["num_distinct_values"] = count_distinct_values

            curr_rec["frequent-entries"]["most_common_tokens"] = dict()
            if field in field_token_count:
                dict_tokens = field_token_count[field]
                sorted_dict_tokens = sorted(dict_tokens.items(), key=operator.itemgetter(1), reverse=True)
                countNonOneTokens = 0
                for k, v in sorted_dict_tokens:
                    if v == 1:
                        count_distinct_tokens = len(sorted_dict_tokens) - countNonOne
                        break
                    countNonOneTokens += 1
                # print sorted_dict_vals
                temp_dict_tokens = OrderedDict()
                for k, v in sorted_dict_tokens[:topk]:
                    temp_dict_tokens[k] = v

                curr_rec["frequent-entries"]["most_common_tokens"] = temp_dict_tokens
                curr_rec["length"]["num_distinct_tokens"] = count_distinct_tokens

            curr_rec["frequent-entries"]["most_common_numeric_tokens"] = dict()
            if field in field_token_numeric_count:
                dict_tokens_num = field_token_numeric_count[field]
                sorted_dict_tokens_num = sorted(dict_tokens_num.items(), key=operator.itemgetter(1), reverse=True)

                # print sorted_dict_vals
                temp_dict_tokens_num = OrderedDict()
                for k, v in sorted_dict_tokens_num[:topk]:
                    temp_dict_tokens_num[k] = v

                curr_rec["frequent-entries"]["most_common_numeric_tokens"] = temp_dict_tokens_num

            curr_rec["frequent-entries"]["most_common_alphanumeric_tokens"] = dict()
            if field in field_token_alpha_numeric_count:
                dict_tokens_alphanum = field_token_alpha_numeric_count[field]
                sorted_dict_tokens_alphanum = sorted(dict_tokens_alphanum.items(), key=operator.itemgetter(1),
                                                     reverse=True)

                # print sorted_dict_vals
                temp_dict_tokens_alphanum = OrderedDict()
                for k, v in sorted_dict_tokens_alphanum[:topk]:
                    temp_dict_tokens_alphanum[k] = v

                curr_rec["frequent-entries"]["most_common_alphanumeric_tokens"] = temp_dict_tokens_alphanum

            curr_rec["frequent-entries"]["most_common_punctuation"] = dict()
            if field in field_punctuation_count:
                dict_tokens_punctuation = field_punctuation_count[field]
                sorted_dict_tokens_punctuation = sorted(dict_tokens_punctuation.items(), key=operator.itemgetter(1),
                                                        reverse=True)

                # print sorted_dict_vals
                temp_dict_tokens_punctuation = OrderedDict()
                for k, v in sorted_dict_tokens_punctuation[:topk]:
                    temp_dict_tokens_punctuation[k] = v

                curr_rec["frequent-entries"]["most_common_punctuation"] = temp_dict_tokens_punctuation

            curr_rec["length"]["character"]=dict()
            curr_rec["length"]["token"] = dict()
            if field in field_value_len:
                curr_rec["length"]["character"]["average"] = np.mean(field_value_len[field])
                curr_rec["length"]["character"]["standard-deviation"] = np.std(field_value_len[field])
            if field in field_token_len:
                curr_rec["length"]["token"]["average"] = np.mean(field_token_len[field])
                curr_rec["length"]["token"]["standard-deviation"] = np.std(field_token_len[field])


            if field in field_value_numeric:
                curr_rec["length"]["numeric_data_stats"] = dict()
                #print "numeric field" + field
                curr_rec["length"]["numeric_data_stats"]["min"] = np.min(field_value_numeric[field])
                curr_rec["length"]["numeric_data_stats"]["max"] = np.max(field_value_numeric[field])
                curr_rec["length"]["numeric_data_stats"]["average"] = np.mean(field_value_numeric[field])
                curr_rec["length"]["numeric_data_stats"]["standard-deviation"] = np.std(field_value_numeric[field])
                curr_rec["length"]["numeric_data_stats"]["quartile"] = dict()
                try:
                    curr_rec["length"]["numeric_data_stats"]["quartile"]["q1"] = np.percentile(field_value_numeric[field], 25)
                    curr_rec["length"]["numeric_data_stats"]["quartile"]["q2"] = np.percentile(field_value_numeric[field], 50)
                    curr_rec["length"]["numeric_data_stats"]["quartile"]["q3"] = np.percentile(field_value_numeric[field], 75)
                except:
                    pass
                try:
                    curr_rec["length"]["numeric_data_stats"]["mode"] = np.argmax(np.bincount(field_value_numeric[field]))
                except:
                    #print "Improper mode"
                    #print field
                    #print curr_rec
                    pass

            if field in field_language:
                curr_rec["language"] = dict()
                curr_rec["language"] = field_language[field]

            res[field] = curr_rec
            res["num_record"] = len(fields)
        except Exception as e:
            print(e)
            raise
            #pass
    print(res)

    ans = json.dumps(res)
    f = open(outputFile, 'w')
    f.write(ans)
    f.close()


if __name__ == '__main__':
    if len(sys.argv) > 1 : profile_data(sys.argv[1],sys.argv[2],int(sys.argv[3]))
    else: profile_data('gazetteer.db','gazetteer_database_profile.json', 20)
    print("--- %s seconds ---" % (time.time() - start_time))

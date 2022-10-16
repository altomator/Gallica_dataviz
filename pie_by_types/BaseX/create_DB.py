# -*- coding: utf-8 -*-
# Create a new BaseX database
# Documentation: https://docs.basex.org/wiki/Clients

# Usage : python3 create-DB.py -data FILE -name DATABASE_NAME


from BaseXClient import BaseXClient
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-data","-d",  help="XML data file", required=True)
parser.add_argument("-name","-n",  help="Name of the BaseX database", required=True)
args = parser.parse_args()

# load XML file
with open(args.data, 'r') as f:
    data = f.read()

# create session
session = BaseXClient.Session('localhost', 1984, 'admin', 'admin')

try:
    # create new database
    session.create(args.name, data)
    print(session.info())

    # run query on database
    #print("\n" + session.execute("xquery doc('"+args.name+"')"))

    # drop database
    #session.execute("drop db database")
    #print(session.info())

finally:
    # close session
    if session:
        session.close()

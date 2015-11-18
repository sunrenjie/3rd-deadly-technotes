# This file contains example code from section 2.1 Object Relational Tutorial
# from documentation for sqlalchemy version 0.9.7.

import re # for judging database type

import sqlalchemy
from sqlalchemy import create_engine

db = 'sqlite:///:memory:'
#db = 'mysql://root:r@localhost'

engine = create_engine(db, echo=True)

if re.match("mysql://", db): # MySQL-specific preparation
    engine.execute("DROP DATABASE IF EXISTS al4orm")
    engine.execute("CREATE DATABASE IF NOT EXISTS al4orm")
    engine.execute("USE al4orm")

from sqlalchemy.ext.declarative import declarative_base
Base = declarative_base()

from sqlalchemy import Column, Integer, String, Sequence, Boolean
class User(Base):
    __tablename__ = 'users'
    # Firebird/Oracle requires sequences to generate new primary key
    # identifiers.
    id = Column(Integer, Sequence('user_id_seq'), primary_key=True)
    name = Column(String(50))
    fullname = Column(String(50))
    password = Column(String(50))
    is_valid = Column(Boolean)

    def __repr__(self):
        return "<User(name='%s', fullname='%s', password='%s')>" % (
            self.name, self.fullname, self.password)

Base.metadata.create_all(engine)

from sqlalchemy.orm import sessionmaker
Session = sessionmaker(bind=engine)
session = Session()
session.add(User(id=1, name='foo', fullname='FOO', password='x', is_valid=True))
session.add(User(id=2, name='bar', fullname='BAR', password='y', is_valid=False))
session.commit()
q1 = session.query(User).filter(User.is_valid)
q2 = session.query(User).filter(not User.is_valid)
q3 = session.query(User).filter(User.is_valid == False)
print 'q1==%s' % q1[0]
try:
  print 'q2==%s' % q2[0]
except:
  pass
print 'q3==%s' % q3[0]


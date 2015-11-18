# This file contains example code from section 3.1 SQL Expression Language
# Tutorial of documentation for sqlalchemy version 0.9.7.

import re # for judging database type

import sqlalchemy
from sqlalchemy import create_engine

db = 'sqlite:///:memory:'
db = 'mysql://root:r@localhost'

engine = create_engine(db, echo=True)

if re.match("mysql://", db): # MySQL-specific preparation
    engine.execute("DROP DATABASE IF EXISTS al4test")
    engine.execute("CREATE DATABASE IF NOT EXISTS al4test")
    engine.execute("USE al4test")

from sqlalchemy import Table, Column, Integer, String, MetaData, ForeignKey
metadata = MetaData()
# Note that all String() shall has valid length parameter in order to support
# as many database types as possible.
users = Table('users', metadata,
    Column('id', Integer, primary_key=True),
    Column('name', String(50)),
    Column('fullname', String(100)),
)

addresses = Table('addresses', metadata,
    Column('id', Integer, primary_key=True),
    Column('user_id', None, ForeignKey('users.id')),
    Column('email_address', String(100), nullable=False)
)

metadata.create_all(engine)

conn = engine.connect()

ins = users.insert().values(name='jack', fullname="Jack Jones")
result = conn.execute(ins)

ins = users.insert()
result = conn.execute(ins, id=2, name='wendy', fullname="Wendy Williams")

conn.execute(addresses.insert(), [
  {'user_id': 1, 'email_address' : 'jack@yahoo.com'},
  {'user_id': 1, 'email_address' : 'jack@msn.com'},
  {'user_id': 2, 'email_address' : 'www@www.org'},
  {'user_id': 2, 'email_address' : 'wendy@aol.com'},
])

### selecting
from sqlalchemy.sql import select
s = select([users])
result = conn.execute(s)
for row in result:
  print row
result.close()

result = conn.execute(s)
row = result.fetchone()
print "name:", row['name'], "; fullname:", row['fullname']
result.close()

for row in conn.execute(s):
  print "name: ", row[users.c.name], "; fullname:", row[users.c.fullname]

s = select([users.c.name, users.c.fullname])
result = conn.execute(s)
for row in result:
  print row
result.close()

s = select([users, addresses]).where(users.c.id == addresses.c.user_id)
for row in conn.execute(s):
  print row

### select via compund binary clauses
from sqlalchemy.sql import and_, or_, not_
s = select([(users.c.fullname + ", " + addresses.c.email_address
            ).label('title')]).where(
              and_(
                users.c.id == addresses.c.user_id,
                users.c.name.between('m', 'z'),
                or_(
                  addresses.c.email_address.like('%@aol.com'),
                  addresses.c.email_address.like('%@msn.com')
                )
              )
            )
for row in conn.execute(s):
    print row

### select via text; the complexity of the conditional code below reflects
### the benefit of using higher level of facilities offered by sqlalchemy:
### they encapsulate these low level details.
from sqlalchemy.sql import text
if re.match("mysql://", db): # MySQL uses CONCAT() rather than "||".
    title = "CONCAT(users.fullname, ', ', addresses.email_address)"
else:
    title = "users.fullname || ', ' || addresses.email_address"
s = ("SELECT " + title + " AS title "
     "FROM users, addresses "
     "WHERE users.id == addresses.user_id "
     "AND users.name BETWEEN :x AND :y "
     "AND (addresses.email_address LIKE :e1 OR "
     "     addresses.email_address LIKE :e2)")
if re.match("mysql://", db): # MySQL uses "==" rather than "=".
    s = re.sub("==", "=", s)
s = text(s)
for row in conn.execute(s, x='m', y='z', e1='%@aol.com', e2='%@msn.com'):
    print row

### select with aliases
a1 = addresses.alias()
a2 = addresses.alias()
s = select([users]).where(
      and_(
        users.c.id == a1.c.user_id,
        users.c.id == a2.c.user_id,
        a1.c.email_address.like('%@yahoo.com'),
        a2.c.email_address.like('%@msn.com'),
      ))
for row in conn.execute(s):
    print row

### select + join
s = select([addresses]).select_from(
    users.join(addresses, addresses.c.email_address.like(users.c.name + '%'))
    )
for row in conn.execute(s):
    print row

### execute as you specify parameter using bindparam()
from sqlalchemy.sql import bindparam
# now the generated clauses can serve as templates for use in conn.execute()
s = users.select(users.c.name == bindparam('username'))
for row in conn.execute(s, username='wendy'):
    print row
for row in conn.execute(s, username='jack'):
    print row

### calculate function with different bind parameters
from sqlalchemy.sql import func, column
# calculate is a function accepting two parameters and returning a result set
# of three values, supported in Oracle/PostgreSQL.
calculate = select([column('q'), column('z'), column('r')]
            ).select_from(
              func.calculate(
                bindparam('x'),
                bindparam('y')
              )
            )
calc = calculate.alias()
print select([users]).where(users.c.id > calc.c.z)
# unique_params() is used such that our calculate statement can be used twice.
calc1 = calculate.alias('c1').unique_params(x=17, y=45)
calc2 = calculate.alias('c2').unique_params(x=5, y=12)
s = select([users]).where(users.c.id.between(calc1.c.z, calc2.c.z))
print s
print s.compile().params

# window function
s = select([
        users.c.id,
        func.row_number().over(order_by=users.c.name)
    ])
print s
# The window function is not supported in MySQL, SQLite.
if re.match("mysql://", db) or re.match("sqlite://", db):
    pass
else:
    for row in conn.execute(s):
        print row

### union
from sqlalchemy.sql import union
# The select() clauses below are much more complicated than the ones in the
# original example, because we want to support MySQL, in which case, the
# ORDER BY clause does not accept forms like table-name.column-name. Instead,
# a alias has to be created via label(). See more:
# http://dev.mysql.com/doc/refman/5.6/en/union.html
u = union(
    select([addresses.c.id, addresses.c.user_id,
        addresses.c.email_address.label('eaddr')]).where(
        addresses.c.email_address == 'foo@bar.com'),
    select([addresses.c.id, addresses.c.user_id,
        addresses.c.email_address]).where(
        addresses.c.email_address.like('%@yahoo.com'))).order_by('eaddr')
print u
for row in conn.execute(u):
    print row

from sqlalchemy.sql import except_
# MySQL does not support EXCEPT.
if not re.match("mysql://", db): 
    u = except_(
        addresses.select().where(addresses.c.email_address.like('%@%.com')),
        addresses.select().where(addresses.c.email_address.like('%@msn.com'))
    )
    print u
    for row in conn.execute(u):
        print row
    ### compound operations of except and union
    u = except_(
            union(
                addresses.select().
                    where(addresses.c.email_address.like('%@yahoo.com')),
                addresses.select().
                    where(addresses.c.email_address.like('%@msn.com'))
            ).alias().select(),
            addresses.select(addresses.c.email_address.like('%@msn.com'))
    )
    print u
    for row in conn.execute(u):
        print row

from sqlalchemy.sql import func

### scalar select as correlated subquery
# A correlated subquery is evaluated once for each row in the outer query. For
# a MySQL example, see http://www.mysqltutorial.org/mysql-subquery/ .
stmt = select([func.count(addresses.c.id)]).where(
        users.c.id == addresses.c.user_id).label('address_count')
# Results generated by stmt is determined by the enclosing select(): its
# value of users.c.id is determined by each of the users.c.name. On the other
# hand, conn.execute(select([stmt])) (without any restriction posed by
# enclosing select()) will yield a one-element table containing the number of
# rows in the table addresses.
for row in conn.execute(select([users.c.name, stmt])):
    print row

### another correlated subquery
stmt = select([addresses.c.user_id]).where(
        addresses.c.user_id == users.c.id).where(
        addresses.c.email_address == 'jack@yahoo.com')
# select all users.name with specific email_address.
enclosing_stmt = select([users.c.name]).where(users.c.id == stmt)
for row in conn.execute(enclosing_stmt):
    print row

### explicit correlate and select_from()
# stmt is a clause that given a row from table (correlating) addresses as
# selected, determines the user id, use it to select rows from table users
# such that the name is 'jack', return the id column.
stmt = select([users.c.id]).where(users.c.id == addresses.c.user_id).where(
        users.c.name == 'jack').correlate(addresses)
# The below clause selects from two columns from two tables, leaving ambiguity
# in the choice FROM table; select_from() rides to help by specifying the FROM
# table to be the result of the JOIN operation.
enclosing_stmt = select(
        [users.c.name, addresses.c.email_address]).select_from(
        users.join(addresses)).where(users.c.id == stmt)
# The whole clause selects users.name, addresses.email_address such that the
# name is 'jack'. Two columns from different yet correlated tables are
# selected such that multiple tables are present in the FROM object of the
# outer select; thus comes the explicit correlate in the enclosed select
# clause.
print enclosing_stmt
for row in conn.execute(enclosing_stmt):
    print row


# insert/update with bindparam()
stmt = users.insert().values(
    name=bindparam('_name'),
    fullname=bindparam('_name') + " .. name")
conn.execute(stmt, [
    {'id': 4, '_name': 'name1'},
    {'id': 5, '_name': 'name2'},
    {'id': 6, '_name': 'name3'},
])
for row in conn.execute(select([users])):
    print row

stmt = users.update().where(users.c.name == bindparam('oldname')).values(
    name=bindparam('newname'))
conn.execute(stmt, [
    {'oldname': 'jack', 'newname': 'ed'},
    {'oldname': 'wendy', 'newname': 'mary'},
    {'oldname': 'jim', 'newname': 'jake'},
    ])
for row in conn.execute(select([users])):
    print row

stmt = select([addresses.c.email_address]).where(
    addresses.c.user_id == users.c.id).limit(1)
conn.execute(users.update().values(fullname=stmt))
for row in conn.execute(select([users])):
    print row


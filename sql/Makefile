.SUFFIXES:
.PHONY: FORCE

PGHOST:=respgsql
PGUSER:=rkh
PGDATABASE:=csb-dev
export PGHOST
export PGUSER
export PGDATABASE

TS:=$(shell date '+%Y%m%d')

default: pgutils.sql

# dump database without owner but with ACLs so that
# public gets access.  Unfortunately ACLs necessitates
# stripping non-public ownership with perl. 
pgutils.sql: pgutils-update-readme
	pg_dump --no-owner -n pgutils -Fp \
	| perl -ne 'print unless (m/^(?:GRANT|REVOKE).+(?:TO|FROM) (?!PUBLIC)/)' >"$@"

# Insert the file README into the database
# TS is inserted at the first \n\n\n
pgutils-update-readme: ../README FORCE
	perl -wp0 \
	-e 'BEGIN {' \
	-e '  $$q="\$$_\$$";' \
	-e '  print("truncate pgutils.readme;\n");' \
	-e '  print("insert into pgutils.readme (readme) values ($$q\n");' \
	-e '}' \
	-e 's/\n\n\n/\nRelease: ${TS}\n\n/;' \
	-e 'END { print("$$q);\n") }' <$< \
	| psql -f-


# OBSOLETE:
# .PHONY: push
# push: pgutils.sql-push
# %-push: %
# 	rsync -av $< hn:public_html/reece/pgutils/



.PHONY: clean cleaner cleanest
clean:
	/bin/rm -f *~
cleaner: clean
cleanest: cleaner
	/bin/rm -f pgutils*pgdump
	/bin/rm -f pgutils*tar.gz
	/bin/rm -f pgutils-2*

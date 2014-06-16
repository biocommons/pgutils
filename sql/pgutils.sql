--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: pgutils; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgutils;


SET search_path = pgutils, pg_catalog;

--
-- Name: column_descriptions; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW column_descriptions AS
    SELECT n.nspname, c.relname, c.relkind, a.attname, d.description FROM (((pg_attribute a JOIN pg_class c ON ((a.attrelid = c.oid))) JOIN pg_namespace n ON ((c.relnamespace = n.oid))) LEFT JOIN pg_description d ON ((((a.attrelid = d.objoid) AND (a.attnum = d.objsubid)) AND (d.classoid = ('pg_class'::regclass)::oid)))) WHERE ((a.attnum > 0) AND ((c.relkind = 'v'::"char") OR (c.relkind = 'r'::"char")));


--
-- Name: VIEW column_descriptions; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW column_descriptions IS 'all column descriptions';


--
-- Name: database_sizes; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW database_sizes AS
    SELECT x.size_mb, x.datname FROM (SELECT 1 AS _order, round(((pg_database_size(pg_database.datname))::numeric / 1000000.0), 2) AS size_mb, pg_database.datname FROM pg_database UNION SELECT 2 AS _order, round(sum(((pg_database_size(pg_database.datname))::numeric / 1000000.0)), 2) AS size_mb, 'TOTAL' AS datname FROM pg_database) x ORDER BY x._order, x.datname;


--
-- Name: VIEW database_sizes; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW database_sizes IS 'all databases and sizes [in SI MB (10^6 bytes)]';


--
-- Name: dependencies; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW dependencies AS
    SELECT DISTINCT pc.relkind AS r_relkind, pn.nspname AS p_nspname, pc.relname AS p_relname, cc.relkind AS c_relkind, cn.nspname AS c_namespace, cc.relname AS c_relname FROM ((((pg_depend d JOIN pg_class cc ON ((d.objid = cc.oid))) JOIN pg_class pc ON ((d.refobjid = pc.oid))) JOIN pg_namespace cn ON ((cc.relnamespace = cn.oid))) JOIN pg_namespace pn ON ((pc.relnamespace = pn.oid))) WHERE ((pc.relkind = ANY (ARRAY['i'::"char", 'r'::"char"])) AND (cc.relkind = ANY (ARRAY['i'::"char", 'r'::"char"]))) ORDER BY pn.nspname, pc.relname, pc.relkind, cn.nspname, cc.relname, cc.relkind;


--
-- Name: VIEW dependencies; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW dependencies IS 'all table, index dependencies (no views, yet)';


--
-- Name: foreign_keys; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW foreign_keys AS
    SELECT fkn.nspname AS fk_namespace, fkr.relname AS fk_relation, fka.attname AS fk_column, fka.attnotnull AS fk_notnull, (EXISTS (SELECT pg_index.indexrelid, pg_index.indrelid, pg_index.indkey, pg_index.indclass, pg_index.indnatts, pg_index.indisunique, pg_index.indisprimary, pg_index.indisclustered, pg_index.indexprs, pg_index.indpred FROM pg_index WHERE ((pg_index.indrelid = fkr.oid) AND (pg_index.indkey[0] = fka.attnum)))) AS fk_indexed, pkn.nspname AS pk_namespace, pkr.relname AS pk_relation, pka.attname AS pk_column, (EXISTS (SELECT pg_index.indexrelid, pg_index.indrelid, pg_index.indkey, pg_index.indclass, pg_index.indnatts, pg_index.indisunique, pg_index.indisprimary, pg_index.indisclustered, pg_index.indexprs, pg_index.indpred FROM pg_index WHERE ((pg_index.indrelid = pkr.oid) AND (pg_index.indkey[0] = pka.attnum)))) AS pk_indexed, ((c.confupdtype)::text || (c.confdeltype)::text) AS ud, cn.nspname AS c_namespace, c.conname AS c_name FROM (((((((pg_constraint c JOIN pg_namespace cn ON ((cn.oid = c.connamespace))) JOIN pg_class fkr ON ((fkr.oid = c.conrelid))) JOIN pg_namespace fkn ON ((fkn.oid = fkr.relnamespace))) JOIN pg_attribute fka ON (((fka.attrelid = c.conrelid) AND (fka.attnum = ANY (c.conkey))))) JOIN pg_class pkr ON ((pkr.oid = c.confrelid))) JOIN pg_namespace pkn ON ((pkn.oid = pkr.relnamespace))) JOIN pg_attribute pka ON (((pka.attrelid = c.confrelid) AND (pka.attnum = ANY (c.confkey))))) WHERE (c.contype = 'f'::"char");


--
-- Name: VIEW foreign_keys; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW foreign_keys IS 'PK-FK constraints, including indexes and cascade traits';


--
-- Name: foreign_keys_missing_indexes; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW foreign_keys_missing_indexes AS
    SELECT foreign_keys.fk_namespace, foreign_keys.fk_relation, foreign_keys.fk_column, foreign_keys.fk_notnull, foreign_keys.fk_indexed, foreign_keys.pk_namespace, foreign_keys.pk_relation, foreign_keys.pk_column, foreign_keys.pk_indexed, foreign_keys.ud, foreign_keys.c_namespace, foreign_keys.c_name FROM foreign_keys WHERE ((foreign_keys.ud ~ '[^a]'::text) AND (NOT foreign_keys.fk_indexed)) ORDER BY foreign_keys.pk_relation, foreign_keys.pk_column, foreign_keys.fk_relation, foreign_keys.fk_column;


--
-- Name: VIEW foreign_keys_missing_indexes; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW foreign_keys_missing_indexes IS 'foreign keys with cascading constrains that do not have indexes';


--
-- Name: foreign_keys_pp; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW foreign_keys_pp AS
    SELECT ((((((foreign_keys.fk_namespace)::text || '.'::text) || (foreign_keys.fk_relation)::text) || '('::text) || (foreign_keys.fk_column)::text) || ')'::text) AS fk, ((((((foreign_keys.pk_namespace)::text || '.'::text) || (foreign_keys.pk_relation)::text) || '('::text) || (foreign_keys.pk_column)::text) || ')'::text) AS pk, ((((((foreign_keys.c_namespace)::text || '.'::text) || (foreign_keys.c_name)::text) || '('::text) || foreign_keys.ud) || ')'::text) AS "constraint", foreign_keys.fk_indexed, foreign_keys.fk_notnull, foreign_keys.pk_indexed FROM foreign_keys ORDER BY ((((((foreign_keys.fk_namespace)::text || '.'::text) || (foreign_keys.fk_relation)::text) || '('::text) || (foreign_keys.fk_column)::text) || ')'::text);


--
-- Name: VIEW foreign_keys_pp; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW foreign_keys_pp IS 'PK-FK constraints; see also foreign_keys';


--
-- Name: function_owner_mismatch; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW function_owner_mismatch AS
    SELECT p.oid AS pro_oid, p.proname, p.proowner, up.usename AS pro_usename, p.pronamespace, n.nspname, n.nspowner, un.usename AS nsp_usename FROM (((pg_proc p JOIN pg_user up ON ((p.proowner = up.usesysid))) JOIN pg_namespace n ON ((p.pronamespace = n.oid))) JOIN pg_user un ON ((n.nspowner = un.usesysid))) WHERE (p.proowner <> n.nspowner);


--
-- Name: VIEW function_owner_mismatch; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW function_owner_mismatch IS 'functions whose owner and namespace owner are not equal';


--
-- Name: index_owner_is_not_table_owner; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW index_owner_is_not_table_owner AS
    SELECT nind.nspname AS namespace, i.indrelid AS table_oid, cind.relname AS table_name, uind.usename AS table_owner, i.indexrelid AS index_oid, cindex.relname AS index_name, uindex.usename AS index_owner FROM (((((pg_index i JOIN pg_class cindex ON ((i.indexrelid = cindex.oid))) JOIN pg_class cind ON ((i.indrelid = cind.oid))) JOIN pg_namespace nind ON ((cind.relnamespace = nind.oid))) LEFT JOIN pg_user uindex ON ((cindex.relowner = uindex.usesysid))) LEFT JOIN pg_user uind ON ((cind.relowner = uind.usesysid))) WHERE (cind.relowner <> cindex.relowner);


--
-- Name: VIEW index_owner_is_not_table_owner; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW index_owner_is_not_table_owner IS 'indexes which are not owned by the table owner';


--
-- Name: indexed_tables; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW indexed_tables AS
    SELECT tn.nspname AS schemaname, tc.relname AS tablename, tt.spcname AS tablespace, i.indisunique AS uniq, i.indisprimary AS pk, i.indisclustered AS cluster, ic.relname AS indexname, tt.spcname AS indexspace, pg_get_indexdef(i.indexrelid) AS indexdef FROM (((((pg_index i JOIN pg_class tc ON ((tc.oid = i.indrelid))) JOIN pg_class ic ON ((ic.oid = i.indexrelid))) LEFT JOIN pg_namespace tn ON ((tn.oid = tc.relnamespace))) LEFT JOIN pg_tablespace tt ON ((tt.oid = tc.reltablespace))) LEFT JOIN pg_tablespace it ON ((it.oid = ic.reltablespace))) WHERE ((tc.relkind = 'r'::"char") AND (ic.relkind = 'i'::"char")) ORDER BY tn.nspname, tc.relname, ic.relname;


--
-- Name: VIEW indexed_tables; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW indexed_tables IS 'all indexed tables, with tablespaces and index info';


--
-- Name: indexed_tables_cluster; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW indexed_tables_cluster AS
    SELECT DISTINCT ON (ti1.schemaname, ti1.tablename) ti1.schemaname, ti1.tablename, (SELECT ti2.indexname FROM indexed_tables ti2 WHERE (((ti1.schemaname = ti2.schemaname) AND (ti1.tablename = ti2.tablename)) AND (ti2.cluster = true))) AS cluster_index FROM indexed_tables ti1 ORDER BY ti1.schemaname, ti1.tablename;


--
-- Name: VIEW indexed_tables_cluster; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW indexed_tables_cluster IS 'indexed tables with cluster info (NULL if indexed but not clustered)';


--
-- Name: inherited_tables; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW inherited_tables AS
    SELECT sub.relname AS subtable, sup.relname AS supertable FROM pg_class sup, pg_class sub, pg_depend d WHERE (((sup.oid = d.refobjid) AND (d.objid = sub.oid)) AND (sub.relkind = 'r'::"char")) ORDER BY sub.relname;


--
-- Name: VIEW inherited_tables; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW inherited_tables IS 'inherited table relationships';


--
-- Name: locks; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW locks AS
    SELECT l.pid, d.datname AS database, n.nspname AS schema, c.relname AS relation, l.locktype, l.mode, CASE l.granted WHEN true THEN 'RUN'::text ELSE 'WAIT'::text END AS state, a.usename, a.current_query, to_char((now() - a.query_start), 'HH24:MI:SS'::text) AS duration FROM ((((pg_locks l JOIN pg_database d ON ((l.database = d.oid))) JOIN pg_class c ON ((l.relation = c.oid))) JOIN pg_namespace n ON ((c.relnamespace = n.oid))) JOIN pg_stat_activity a ON ((l.pid = a.procpid))) ORDER BY l.pid, d.datname, n.nspname, c.relname, l.granted;


--
-- Name: VIEW locks; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW locks IS 'granted and pending locks on all relations';


--
-- Name: oid_names; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW oid_names AS
    (SELECT pg_type.oid, 'pg_type' AS pgtable, pg_type.typname AS name FROM pg_type UNION SELECT pg_proc.oid, 'pg_proc' AS pgtable, pg_proc.proname AS name FROM pg_proc) UNION SELECT pg_class.oid, 'pg_class' AS pgtable, pg_class.relname AS name FROM pg_class;


--
-- Name: VIEW oid_names; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW oid_names IS 'names for oids in pg_class, pg_proc, pg_type; coverage is better than ::regclass';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: readme; Type: TABLE; Schema: pgutils; Owner: -; Tablespace: 
--

CREATE TABLE readme (
    readme text
);


--
-- Name: role_members_v; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW role_members_v AS
    SELECT a1.rolname AS role, a1.rolinherit AS inherit, a1.rolcanlogin AS login, a2.rolname AS member FROM ((pg_auth_members am JOIN pg_authid a1 ON ((am.roleid = a1.oid))) JOIN pg_authid a2 ON ((am.member = a2.oid)));


--
-- Name: VIEW role_members_v; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW role_members_v IS 'roles and members, 1 row per pair';


--
-- Name: as_set(anyelement); Type: AGGREGATE; Schema: pgutils; Owner: -
--

CREATE AGGREGATE as_set(anyelement) (
    SFUNC = array_append,
    STYPE = anyarray,
    INITCOND = '{}'
);


--
-- Name: role_membership_v; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW role_membership_v AS
    SELECT x.role, x.inherit, x.login, count(x.member) AS count, as_set(x.member) AS as_set FROM (SELECT role_members_v.role, role_members_v.inherit, role_members_v.login, role_members_v.member FROM role_members_v ORDER BY role_members_v.member) x GROUP BY x.role, x.inherit, x.login;


--
-- Name: schema_not_owned_by_user; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW schema_not_owned_by_user AS
    SELECT n.nspname, owner.usename FROM ((pg_namespace n JOIN pg_user owner ON ((n.nspowner = owner.usesysid))) JOIN pg_user u ON ((n.nspname = u.usename))) WHERE (n.nspowner <> u.usesysid);


--
-- Name: VIEW schema_not_owned_by_user; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW schema_not_owned_by_user IS 'schemas with the same name as a user but which is not owned by the user';


--
-- Name: table_sizes; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW table_sizes AS
    SELECT round(((pg_total_relation_size(c.oid))::numeric / 1000000.0), 2) AS tot_size_mb, round(((pg_relation_size(c.oid))::numeric / 1000000.0), 2) AS rel_size_mb, s.nspowner, so.usename AS nspowner_name, s.nspname, c.relowner, co.usename AS relowner_name, c.relname FROM (((pg_namespace s JOIN pg_class c ON ((s.oid = c.relnamespace))) JOIN pg_user so ON ((s.nspowner = so.usesysid))) JOIN pg_user co ON ((c.relowner = co.usesysid))) WHERE (c.relkind = 'r'::"char") ORDER BY round(((pg_total_relation_size(c.oid))::numeric / 1000000.0), 2), s.nspname, c.relkind, c.relname;


--
-- Name: VIEW table_sizes; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW table_sizes IS 'all tables and sizes [in SI MB (10^6 bytes)]';


--
-- Name: schema_sizes; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW schema_sizes AS
    SELECT table_sizes.nspname, table_sizes.nspowner_name, sum(table_sizes.tot_size_mb) AS tot_size_mb, sum(table_sizes.rel_size_mb) AS rel_size_mb FROM table_sizes GROUP BY table_sizes.nspname, table_sizes.nspowner_name ORDER BY table_sizes.nspname;


--
-- Name: VIEW schema_sizes; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW schema_sizes IS 'all schemas and sizes [in SI MB (10^6 bytes)]';


--
-- Name: table_cluster_index; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW table_cluster_index AS
    SELECT rn.nspname, rc.relname, (SELECT ic.relname FROM (pg_index i JOIN pg_class ic ON ((i.indexrelid = ic.oid))) WHERE ((rc.oid = i.indrelid) AND (i.indisclustered = true))) AS cluster_index FROM (pg_class rc JOIN pg_namespace rn ON ((rc.relnamespace = rn.oid))) WHERE (rc.relkind = 'r'::"char") ORDER BY rn.nspname, rc.relname;


--
-- Name: VIEW table_cluster_index; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW table_cluster_index IS 'all tables, with cluster index when such exists';


--
-- Name: table_columns; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW table_columns AS
    SELECT n.nspname, c.relname, a.attname FROM ((pg_attribute a JOIN pg_class c ON ((a.attrelid = c.oid))) JOIN pg_namespace n ON ((c.relnamespace = n.oid)));


--
-- Name: VIEW table_columns; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW table_columns IS 'all schema,table,column tuples; primarily useful for consistency checks';


--
-- Name: table_perms; Type: VIEW; Schema: pgutils; Owner: -
--

CREATE VIEW table_perms AS
    SELECT n.nspname AS schemaname, c.relname AS tablename, pg_get_userbyid(c.relowner) AS tableowner, c.relacl AS perms FROM (pg_class c LEFT JOIN pg_namespace n ON ((n.oid = c.relnamespace))) WHERE (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char"])) ORDER BY n.nspname, c.relname;


--
-- Name: VIEW table_perms; Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON VIEW table_perms IS 'all table permissions; primarily useful for consistency checks';


--
-- Name: pk_references(text, text, text, text); Type: FUNCTION; Schema: pgutils; Owner: -
--

CREATE FUNCTION pk_references(nsp text, rel text, col text, expr text, OUT n integer, OUT fk_referent text) RETURNS SETOF record
    AS $$
DECLARE
	v_fkinfo record;
	v_sql text;
	v_countrow record;
	v_total integer = 0;
	v_rc integer;
BEGIN
	-- for...in...execute is the only way to get the results of a dynamic query
	-- This construct is used several times below

	-- check pgtools.foreign_keys to see whether n.r.c is really a PK at all
	-- twould be better to chech pg_constraint for contype=p
	SELECT into v_sql 'SELECT count(*) from pgtools.foreign_keys'
		||' WHERE pk_namespace='''||nsp||''' AND pk_relation='''||rel||''' AND pk_column='''||col||'''';
	FOR v_countrow IN EXECUTE v_sql LOOP
		v_rc = v_countrow.count;
	END LOOP;
	IF v_rc = 0 THEN
		RAISE EXCEPTION '%.%.% is not a primary key or has no foreign key references',nsp,rel,col;
	END IF;

	-- ensure that expr matches anything in the PK column
	v_rc = 0;
	SELECT INTO v_sql 'SELECT count(*) FROM '||nsp||'.'||rel||' WHERE '||col||' '||expr;
	FOR v_countrow IN EXECUTE v_sql LOOP
		v_rc = v_countrow.count;
	END LOOP;
	IF v_rc = 0 THEN
		RAISE WARNING '`% %'' doesn''t match any rows in %.%',col,expr,nsp,rel;
	END IF;

	-- loop over all nsp.rel.col referents to this PK, counting the number of hits per expr
	FOR v_fkinfo IN
		SELECT * from pgtools.foreign_keys
		WHERE pk_namespace=nsp AND pk_relation=rel AND pk_column=col
	LOOP
		SELECT INTO v_sql 
			'SELECT count(*) as n,'''
			||v_fkinfo.fk_namespace||'.'||v_fkinfo.fk_relation||'.'||v_fkinfo.fk_column||''' as fk_referent'
			||' from '||v_fkinfo.fk_namespace||'.'||v_fkinfo.fk_relation
			||' where '||v_fkinfo.fk_column||' '||expr||';';
		FOR v_countrow IN EXECUTE v_sql LOOP
			n = v_countrow.n;
			fk_referent = v_countrow.fk_referent;
			v_total = v_total+n;
			RETURN NEXT;
		END LOOP;

	END LOOP;

	-- return total too
	n = v_total;
	fk_referent = 'total';
	RETURN NEXT;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION pk_references(nsp text, rel text, col text, expr text, OUT n integer, OUT fk_referent text); Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON FUNCTION pk_references(nsp text, rel text, col text, expr text, OUT n integer, OUT fk_referent text) IS 'count number of rows in all tables which reference the column specified by nsp($1),rel($2),col($3) and match expr($4)';


--
-- Name: pk_references(text, text); Type: FUNCTION; Schema: pgutils; Owner: -
--

CREATE FUNCTION pk_references(nrc text, expr text, OUT n integer, OUT fk_referent text) RETURNS SETOF record
    AS $$
DECLARE
	v_nsp text;
	v_rel text;
	v_col text;
	v_row record;
BEGIN
	v_nsp = split_part(nrc,'.',1);
	v_rel = split_part(nrc,'.',2);
	v_col = split_part(nrc,'.',3);
	FOR v_row IN SELECT * FROM pgtools.pk_references(v_nsp,v_rel,v_col,expr) LOOP
		n=v_row.n;
		fk_referent=v_row.fk_referent;
		RETURN NEXT;
	END LOOP;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: FUNCTION pk_references(nrc text, expr text, OUT n integer, OUT fk_referent text); Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON FUNCTION pk_references(nrc text, expr text, OUT n integer, OUT fk_referent text) IS 'count number of rows in all tables which reference the nsp.rel.col($1) and match expr($4)';


--
-- Name: sprintf(text, text, text); Type: FUNCTION; Schema: pgutils; Owner: -
--

CREATE FUNCTION sprintf(text, text, text) RETURNS text
    AS $_$
  my ($string, $args, $delim) = @_;
  my $delsplit = defined $delim ? qr{\Q$delim} : qr{\s+};
  return sprintf($string, (split $delsplit, $args));
$_$
    LANGUAGE plperl;


--
-- Name: FUNCTION sprintf(text, text, text); Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON FUNCTION sprintf(text, text, text) IS 'sprintf(fmt,argstring,dlm): format dlm-delimited argstring using fmt';


--
-- Name: sprintf(text, text); Type: FUNCTION; Schema: pgutils; Owner: -
--

CREATE FUNCTION sprintf(text, text) RETURNS text
    AS $_$
  SELECT sprintf($1,$2,null);
$_$
    LANGUAGE sql;


--
-- Name: FUNCTION sprintf(text, text); Type: COMMENT; Schema: pgutils; Owner: -
--

COMMENT ON FUNCTION sprintf(text, text) IS 'sprintf(fmt,argstring): format whitespace-delimited  argstring using fmt';


--
-- Data for Name: readme; Type: TABLE DATA; Schema: pgutils; Owner: -
--

COPY readme (readme) FROM stdin;
\npgutils -- monitor and identify problems in PostgreSQL databases\n2008-08-02 Reece Hart <reece@harts.net>\nRelease: 20080808\n\npgutils consists of views and functions that I use to catch common\nproblems in schema design, and particularly those problems on which I've\nalready been snagged.  It's very far from being a complete kibitzer for\nall problems.  I will gladly take bug fixes and contributions to expand\nits coverage.\n\nThe code is released under the New BSD License and available at\nhttp://code.google.com/p/pgutils/ .\n\nThe only documentation is `\\dv+ pgutils.'. PostgreSQL >=8.1 is required.\n\nCheers,\nReece\n
\.


--
-- Name: pgutils; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA pgutils FROM PUBLIC;
GRANT USAGE ON SCHEMA pgutils TO PUBLIC;


--
-- Name: column_descriptions; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE column_descriptions FROM PUBLIC;
GRANT SELECT ON TABLE column_descriptions TO PUBLIC;


--
-- Name: database_sizes; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE database_sizes FROM PUBLIC;
GRANT SELECT ON TABLE database_sizes TO PUBLIC;


--
-- Name: dependencies; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE dependencies FROM PUBLIC;
GRANT SELECT ON TABLE dependencies TO PUBLIC;


--
-- Name: foreign_keys; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE foreign_keys FROM PUBLIC;
GRANT SELECT ON TABLE foreign_keys TO PUBLIC;


--
-- Name: foreign_keys_missing_indexes; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE foreign_keys_missing_indexes FROM PUBLIC;
GRANT SELECT ON TABLE foreign_keys_missing_indexes TO PUBLIC;


--
-- Name: foreign_keys_pp; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE foreign_keys_pp FROM PUBLIC;
GRANT SELECT ON TABLE foreign_keys_pp TO PUBLIC;


--
-- Name: function_owner_mismatch; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE function_owner_mismatch FROM PUBLIC;
GRANT SELECT ON TABLE function_owner_mismatch TO PUBLIC;


--
-- Name: index_owner_is_not_table_owner; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE index_owner_is_not_table_owner FROM PUBLIC;
GRANT SELECT ON TABLE index_owner_is_not_table_owner TO PUBLIC;


--
-- Name: indexed_tables; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE indexed_tables FROM PUBLIC;
GRANT SELECT ON TABLE indexed_tables TO PUBLIC;


--
-- Name: indexed_tables_cluster; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE indexed_tables_cluster FROM PUBLIC;
GRANT SELECT ON TABLE indexed_tables_cluster TO PUBLIC;


--
-- Name: inherited_tables; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE inherited_tables FROM PUBLIC;
GRANT SELECT ON TABLE inherited_tables TO PUBLIC;


--
-- Name: locks; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE locks FROM PUBLIC;
GRANT SELECT ON TABLE locks TO PUBLIC;


--
-- Name: oid_names; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE oid_names FROM PUBLIC;
GRANT SELECT ON TABLE oid_names TO PUBLIC;


--
-- Name: readme; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE readme FROM PUBLIC;
GRANT SELECT ON TABLE readme TO PUBLIC;


--
-- Name: role_members_v; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE role_members_v FROM PUBLIC;


--
-- Name: as_set(anyelement); Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON FUNCTION as_set(anyelement) FROM PUBLIC;
GRANT ALL ON FUNCTION as_set(anyelement) TO PUBLIC;


--
-- Name: schema_not_owned_by_user; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE schema_not_owned_by_user FROM PUBLIC;
GRANT SELECT ON TABLE schema_not_owned_by_user TO PUBLIC;


--
-- Name: table_sizes; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE table_sizes FROM PUBLIC;
GRANT SELECT ON TABLE table_sizes TO PUBLIC;


--
-- Name: schema_sizes; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE schema_sizes FROM PUBLIC;
GRANT SELECT ON TABLE schema_sizes TO PUBLIC;


--
-- Name: table_cluster_index; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE table_cluster_index FROM PUBLIC;
GRANT SELECT ON TABLE table_cluster_index TO PUBLIC;


--
-- Name: table_columns; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE table_columns FROM PUBLIC;
GRANT SELECT ON TABLE table_columns TO PUBLIC;


--
-- Name: table_perms; Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON TABLE table_perms FROM PUBLIC;
GRANT SELECT ON TABLE table_perms TO PUBLIC;


--
-- Name: pk_references(text, text, text, text); Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON FUNCTION pk_references(nsp text, rel text, col text, expr text, OUT n integer, OUT fk_referent text) FROM PUBLIC;
GRANT ALL ON FUNCTION pk_references(nsp text, rel text, col text, expr text, OUT n integer, OUT fk_referent text) TO PUBLIC;


--
-- Name: pk_references(text, text); Type: ACL; Schema: pgutils; Owner: -
--

REVOKE ALL ON FUNCTION pk_references(nrc text, expr text, OUT n integer, OUT fk_referent text) FROM PUBLIC;
GRANT ALL ON FUNCTION pk_references(nrc text, expr text, OUT n integer, OUT fk_referent text) TO PUBLIC;


--
-- PostgreSQL database dump complete
--


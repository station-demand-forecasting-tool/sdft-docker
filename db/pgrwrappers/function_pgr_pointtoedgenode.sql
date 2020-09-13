CREATE OR REPLACE FUNCTION "public"."pgr_pointtoedgenode"("edges" text, "pnt" "public"."geometry", "tol" float8)
  RETURNS "pg_catalog"."int4" AS $BODY$

declare
    rr record;
    pct float;
    debuglevel text;

begin
    -- find the closest edge within tol distance
    execute 'select * from ' || _pgr_quote_ident(edges) ||
            ' where st_dwithin(''' || pnt::text ||
            '''::geometry, the_geom, ' || tol || ') order by st_distance(''' || pnt::text ||
            '''::geometry, the_geom) asc limit 1' into rr;

    if rr.the_geom is not null then
        -- deal with MULTILINESTRINGS
        if geometrytype(rr.the_geom)='MULTILINESTRING' THEN
            rr.the_geom := ST_GeometryN(rr.the_geom, 1);
        end if;

        -- project the point onto the linestring
        execute 'show client_min_messages' into debuglevel;
        SET client_min_messages='ERROR';
        pct := st_linelocatepoint(rr.the_geom, pnt);
        execute 'set client_min_messages  to '|| debuglevel;

        -- return the node we are closer to
        if pct < 0.5 then
            return rr.source;
        else
            return rr.target;
        end if;
    else
        -- return a failure to find an edge within tol distance
        return -1;
    end if;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE;
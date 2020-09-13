/*
 In the openroads dataset there are occurrences of groups of streets that are 
 disconnected from the main network.
 These can be the entire road network on an island (e.g. Isle of Wight)
 They can also just small areas on the mainland.
 The latter are a particular problem, as the nearest edge to a postcode or station
 centroid could be part of one of these disconnected network groups. This would impact
 creating station service areas and route distances from postcodes.

 pgr_analyzeGraph can be used to identify isolated edges (edges where nodes on
 both ends are dead ends) but that deals with a fraction of the problem.

 The pgRouting function pgr_connectedComponents() - see:
 https://docs.pgrouting.org/latest/en/pgr_connectedComponents.html
 groups every source or target node in the edge table
 into components. All nodes (vertices) that share the same component number are
 reachable from each other.

 When pgr_connectedComponents() is run the result has a row for every node indicating
 which component it is a member of. The component that represents the main graph will vary,
 and you have to identify which component has the majority of edges.

 Once the nodes that are not part of component 1 are identified they can be used to
 delete any edge which has a matching target node (we don't need to check source
 node as well). And any matching node can be deleted from the node table.

 As the demand model is only to be used for mainland GB, it is fine that we are
 removing island networks (not connected by road) too.
 */
 
-- create a table of the disconnected nodes
-- the inner query is simply identifying the component with the most
-- nodes (i.e. the main graph).
 
create table openroads.disconnected as
 (
 select node from pgr_connectedcomponents(
    'select id, source, target, cost_len as cost, rcost_len as reverse_cost from
    openroads.roadlinks'
	) where component not in 
		(
with tmp as (
select count(*), component from pgr_connectedcomponents(
    'select id, source, target, cost_len as cost, rcost_len as reverse_cost from
    openroads.roadlinks'
) group by component order by count desc limit 1
) select component from tmp
		)
) ;

-- delete the isolated edges
delete from openroads.roadlinks
where target in (select node from openroads.disconnected);

-- delete the isolated nodes
delete from openroads.roadnodes
where id in (select node from openroads.disconnected);

-- delete the disconnected table
drop table openroads.disconnected cascade;
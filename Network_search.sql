CREATE procedure [dbo].[Network_search] as

-- drop tables about to be created
if object_id('dbo.network_search_edges', 'U') is not null drop table dbo.network_search_edges
if object_id('dbo.network_search_vertices', 'U') is not null drop table dbo.network_search_vertices
if object_id('dbo.network_search_input_terms', 'U') is not null drop table dbo.network_search_input_terms
if object_id('dbo.network_search_input_nodes', 'U') is not null drop table dbo.network_search_input_nodes

-- REQUIREMENTS
-- uses a table for network nodes called 'dbo.vertices, with column node_id linked to below table'
-- uses a table for network edges called 'dbo.edges, with colums node_1 and node_2 to identify the linked entities'


-- declare and set variables needed
declare @terms nvarchar(max)
set @terms = N'someterm' -- used for fuzzy searching in the network for varchar term


-- insert search terms
select * 
into network_search_input_terms
from (
	select terms = @terms
	) x


-- get node ids from search terms with like fuzzy search
select
	node_id
into 
	dbo.network_search_input_nodes
from 
	dbo.vertices v
inner join 
	dbo.network_search_input_terms t
	on v.name like '%' + t.terms + '%'

;

-- build loop of search nodes from 'network_search_input' table
with cte as
(

	select 
		 node_1
		,node_2 
		,level = 0 
		,sentinel = convert(nvarchar(max), node_1)
	from 
		dbo.edges
	where 
		node_1 in (select node_id from dbo.network_search_input_nodes)
		or node_2 in (select node_id from dbo.network_search_input_nodes)

	union all

	select 
		 e.node_1
		,e.node_2
		,level + 1
		,sentinel + N'|' + convert(nvarchar(max), cte.node_2) -- sentinel is used in case we run into repeated network links, e.g. a-b and b-a
	from 
		dbo.edges e
	inner join 
		cte 
		on e.node_1 = cte.node_1
		or e.node_1 = cte.node_2
	where 
		charindex(convert(nvarchar(max), cte.node_2), sentinel) = 0

)
select 
	 node_1
	,node_2
	,level = min(level)
into
	dbo.network_search_edges
from 
	cte
group by 
	node_1
	,node_2


-- get all vertices from output table of network search
select distinct
	v.*
into 
	dbo.network_search_vertices
from 
	dbo.vertices v
where 
	v.node_id in (select node_1 from dbo.network_search_edges)
	or v.node_id in (select node_2 from dbo.network_search_edges)

-- display results
select * from dbo.network_search_vertices
select * from dbo.network_search_edges
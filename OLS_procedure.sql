Create procedure [dbo].[ols_procedure](@x varchar(100), @y varchar(100), @table varchar(100))
as
begin

-- exec dbo.ols2 '[aexperc]','[aegperc]','[dbo].[sample]'

-- drop temp tables to be created
	IF OBJECT_ID ('dbo.[ols_stats]') IS NOT NULL DROP TABLE dbo.ols_stats
	IF OBJECT_ID ('dbo.[ols_stats2]') IS NOT NULL DROP TABLE dbo.ols_stats2

-- create results table
	if OBJECT_ID ('dbo.[ols_results]') is null  
		begin
			create table dbo.ols_results (
				 created datetime
				,x varchar(100)
				,y varchar(100)
				,source varchar(100)
				,count_y int
				,count_x int
				,count_xy int
				,b0 decimal(38,10)
				,b1 decimal(38,10)
				,r2 float
				)
		end 

-- declare all variables
	declare 
		 @n varchar(100)
		,@sql varchar(4000) 
		,@sumX float
		,@sumY float
		,@sumXX float
		,@sumYY float
		,@sumXY float
		,@Sxx float
		,@Syy float
		,@Sxy float
		,@SSreg float
		,@SStot float
		,@SSerr	float

-- calculate preliminary statistics
	set @sql = '
		declare @y_avg float = (select avg(' + @y + ') from ' + @table + ')
		
		Select 
			rownum = 1 
			,n = count(*)
			,average_x = avg(' + @x + ')
			,average_y = avg(' + @y + ')
			,sumX = sum(' + @x + ')
			,sumY = sum(' + @y + ')
			,sumXX = sum(' + @x + '*' + @x + ')
			,sumYY = sum(' + @y + '*' + @y + ')
			,sumXY = sum(' + @x + '*' + @y + ')
			,SStot = sum(power((' + @y + ' - @y_avg), 2))
			,SSreg = sum(power((' + @x + ' - @y_avg), 2))
			,SSerr = sum(power((' + @y + ' - ' + @x + '), 2))
		into ols_stats
		from ' + @table + '
		where ' + @y + ' is not null and ' + @x + ' is not null'
	print(@sql)
	exec (@sql)

-- set standard deviations & required variables
	set @n		= (select n from ols_stats where rownum = 1)
	set @sumX	= (select sumX from ols_stats where rownum = 1)
	set @sumY	= (select sumY from ols_stats where rownum = 1)
	set @sumXX	= (select sumXX from ols_stats where rownum = 1)
	set @sumYY	= (select sumYY from ols_stats where rownum = 1)
	set @sumXY	= (select sumXY from ols_stats where rownum = 1)
	set @SSreg	= (select SSreg from ols_stats where rownum = 1)
	set @SStot	= (select SStot from ols_stats where rownum = 1)
	set @SSerr	= (select SSerr from ols_stats where rownum = 1)

	set @Sxx	= (@sumXX - (@sumX * @sumX)) / @n
	set @Syy	= (@sumYY - (@sumY * @sumY)) / @n
	set @Sxy	= (@sumXY - (@sumX * @sumY)) / @n
	
	select
		 rownum		= 1
	--	,r2			= 1- (@SSerr / @SStot) -- Incorrectly calculated
		,r2			= power((@n * @sumXY - @sumX * @sumY) / sqrt((@n * @sumXX - power(@sumX, 2)) * (@n * @sumYY - power(@sumY, 2))), 2)
	into ols_stats2

-- start the calculation
	set @sql = '
		insert into dbo.ols_results

		select 
			created		= current_timestamp
			,x			= ''' + @x + '''
			,y			= ''' + @y + '''
			,source		= ''' + @table + '''
			,count_y	= (select count(' + @y + ') from ' + @table + ' where ' + @y + ' is not null)
			,count_x	= (select count(' + @x + ') from ' + @table + ' where ' + @x + ' is not null)
			,count_xy	= (select count(' + @x + ') from ' + @table + ' where ' + @x + ' is not null and ' + @y + ' is not null)
			,b0			= ((' + @n + ' * sum(' + @x + ' * ' + @y + ')) - (sum(' + @x + ')*sum(' + @y + ')))/((' + @n + ' * sum(Power(' + @x + ',2)))-Power(Sum(' + @x + '),2))
			,b1			= avg(' + @y + ') - ((' + @n + ' * sum(' + @x + ' * ' + @y + ')) - (sum(' + @x + ')*sum(' + @y + ')))/((' + @n + ' * sum(Power(' + @x + ',2)))-Power(Sum(' + @x + '),2)) * avg(' + @x + ')
			,r2			= (select r2 from ols_stats2 where rownum = 1)
		from ' + @table + '
		where ' + @y + ' is not null 
			and ' + @x + ' is not null
			'
	print @sql
	exec(@sql)

-- display results on screen
	select top 1 * from dbo.ols_results where created = (select max(created) from dbo.ols_results)

-- cleanup
	IF OBJECT_ID ('dbo.[ols_stats]') IS NOT NULL DROP TABLE dbo.ols_stats
	IF OBJECT_ID ('dbo.[ols_stats2]') IS NOT NULL DROP TABLE dbo.ols_stats2

end
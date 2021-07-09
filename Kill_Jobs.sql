

IF OBJECT_ID('tempdb..#tmpjobs') IS NOT NULL DROP TABLE #tmpjobs;
			CREATE TABLE #tmpjobs (
			[ID] [int] IDENTITY(1,1) NOT NULL
			 ,[job_id]	nvarchar(max)
			,[job_name]	nvarchar(max)
			,[start_execution_date]	nvarchar(max)							
			,[accion]nvarchar(max)
			,[day] nvarchar(max)
			,[dur]nvarchar(max)
			,[dur2]	nvarchar(max)
			,[current_executed_step_id] nvarchar(max)
			,[step_name] nvarchar(max)
			);


insert INTO #tmpjobs
SELECT
   ja.job_id,
    j.name AS job_name,
    ja.start_execution_date,
	iif(datediff(HOUR, ja.start_execution_date,   getdate())>2, 'Matar','No Matar') as accion,
	datediff(dd, ja.start_execution_date,   getdate()) [day],
	DATEADD(ms, datediff(SS, ja.start_execution_date,   getdate()) * 1000, 0) dur,
	CONVERT(varchar, DATEADD(ms, datediff(SS, ja.start_execution_date,   getdate()) * 1000, 0), 114) dur2,
    ISNULL(last_executed_step_id,0)+1 AS current_executed_step_id,
    Js.step_name
FROM msdb.dbo.sysjobactivity ja 
LEFT JOIN msdb.dbo.sysjobhistory jh 
    ON ja.job_history_id = jh.instance_id
JOIN msdb.dbo.sysjobs j 
ON ja.job_id = j.job_id
JOIN msdb.dbo.sysjobsteps js
    ON ja.job_id = js.job_id
    AND ISNULL(ja.last_executed_step_id,0)+1 = js.step_id
WHERE ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)
AND start_execution_date is not null
AND stop_execution_date is null
order by ja.start_execution_date



declare @tabla table (job_id nvarchar(max), job_name nvarchar(max), accion nvarchar(max))
insert into @tabla (job_id,job_name,Accion) select m.job_id,m.job_name,m.accion from #tmpjobs m where accion ='Matar'

declare @cont int
set @cont = 1
declare @cant int = (select count(*) from @tabla)

--select @count

while @cont <= @cant
begin 

	declare @jobName nvarchar(max) = 'N'''+(select top (1) job_name from @tabla order by job_id)+ ''''
	--PRINT @jobName
	exec dbo.sp_stop_job @jobName 
	set @cont  = @cont  + 1  

end

--select * from #tmpjobs

IF OBJECT_ID('tempdb..#tmpjobs') IS NOT NULL DROP TABLE #tmpjobs;

GO


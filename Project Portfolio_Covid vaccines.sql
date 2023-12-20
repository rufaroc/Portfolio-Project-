Select * 
from PortfolioProject..CovidDeaths$
where continent is not null
order by 3,4
;


--Select * 
--from PortfolioProject..CovidVaccinations$
--order by 3,4
--;

--Select Data that we are goin to be using 

Select Location, date, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths$
where continent is not null
order by 1, 2

-- Looking at new cases vs total deaths
Select Location, date, new_cases, total_deaths
From PortfolioProject..CovidDeaths$
where location like '%states%'
order by 1, 2

--Lookign at the new case rate
Select Location, date, population, new_cases, (new_cases/population)* 100 as new_case_rate
From PortfolioProject..CovidDeaths$
where location like '%states%'
where continent is not null
order by 1, 2

-- Looking at countries with highest new case rate vs population 
SELECT
    Location,
    population,
    MAX(new_cases) AS max_new_cases,
    MAX(CONVERT(float, new_cases)) / NULLIF(CONVERT(float, population), 0) * 100 AS new_case_percentage
FROM
    PortfolioProject..CovidDeaths$
WHERE
    continent IS NOT NULL
GROUP BY
    Location, population
ORDER BY
    population DESC;


-- LETS BREAK THIS DOWN BY CONTINENT 

-- showing continents with highest death count per population
Select 
	continent, 
	MAX(convert(int, total_deaths)) as total_death_count
From PortfolioProject..CovidDeaths$
--where location like '%states%'
where 
	continent is not null
Group by 
	continent
order by 
	total_death_count desc

---- GLOABAL NUMBERS
 Select
	date, 
	SUM(new_cases) as total_new_cases, 
	SUM(cast(new_deaths as int)) as total_new_deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases)* 100 as deathpercentage
From PortfolioProject..CovidDeaths$
--where location like '%states%'
where continent is not null 
group by
	date
order by 
	1, 2, 3


-- Looking at total population vs vacinations


-- USE CTE
-- Total new cases vs total vacinated who have vaccines
Select 
	dea.continent, 
	dea.location,
	dea.new_cases,
	vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) as total_newvaccines 
	--OVER (Partition by dea.location, 
	--ORDER by dea.location, dea.date)
from PortfolioProject..CovidDeaths$ dea
Join PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location 
	and dea.date = vac.date
where 
	dea.continent is not null;


SELECT 
    dea.continent, 
    dea.location,
    dea.new_cases,
    vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as bigint)) 
	OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as rolling_newvaccinations 
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
Order BY
   1,2,3


With PopvsVac
	(continent, location, new_cases, new_vaccinations, rolling_newvaccinations)
as 
(
SELECT 
    dea.continent, 
    dea.location,
    dea.new_cases,
    vac.new_vaccinations,
    SUM(cast(vac.new_vaccinations as bigint)) 
	OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as rolling_newvaccinations 
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
   )
Select *, 
(rolling_newvaccinations/NULLIF(new_cases,0)) * 100
from PopvsVac



-- Temp Table

Create Table #PercentVacinated
(
Continent nvarchar(255), 
location nvarchar(255),
date datetime,
new_vaccinations numeric, 
new_cases numeric,
rolling_newvaccinations numeric
)

Insert into #PercentVacinated

SELECT 
    dea.continent, 
    dea.location,
    dea.new_cases,
    vac.new_vaccinations,
	dea.date,
    SUM(cast(vac.new_vaccinations as bigint)) 
	OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as rolling_newvaccinations 
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL

Select *, 
(rolling_newvaccinations/NULLIF(new_cases,0)) * 100
from #PercentVacinated

--- test 
Drop Table if exists #PercentVaccinated
CREATE TABLE #PercentVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    New_Vaccinations NUMERIC,
    New_Cases NUMERIC,
    Rolling_NewVaccinations NUMERIC
)

INSERT INTO #PercentVaccinated
SELECT 
    dea.continent, 
    dea.location,
    dea.date,
    dea.new_cases,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) as rolling_newvaccinations 
FROM 
    PortfolioProject..CovidDeaths$ dea
JOIN 
    PortfolioProject..CovidVaccinations$ vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;

SELECT 
    *,
    (rolling_newvaccinations / NULLIF(New_Cases, 0)) * 100 AS PercentVaccinated
FROM 
    #PercentVaccinated;


-- Create view for visualizations 
Use PortfolioProject
Go
Create View PercentVaccinated as
SELECT 
    dea.continent, 
    dea.location,
    dea.new_cases,
    vac.new_vaccinations,
	dea.date,
    SUM(cast(vac.new_vaccinations as bigint)) 
	OVER (PARTITION BY dea.location ORDER by dea.location, dea.date) as rolling_newvaccinations 
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
    ON dea.location = vac.location 
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL

Select *
From 
PercentVaccinated


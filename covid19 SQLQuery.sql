Select *
From project..CovidDeath
where continent is not null
Order by 3,4

--Select *
--From project..CovidVaccinations
--Order by 3,4;

--Select the data that we are going to use

Select location, date, total_cases, new_cases, total_deaths, population
From project..CovidDeath
where continent is not null
Order by 1,2

--looking at total cases vs total deaths
--shows likelihood of dying if you contact covid in your country

Select location, date, total_cases, total_deaths, 
CAST(total_deaths AS float)/CAST(total_cases AS float)*100 AS DeathPercentage
From project..CovidDeath
Where location like '%states%'
and continent is not null
Order by 1,2


--looking at total cases vs populations
--shows what percentage of population got covid

Select location, date, population, total_cases,  
CAST(total_cases AS float)/CAST(population AS float)*100 AS PercentPopulationInfected
From project..CovidDeath
where continent is not null
--Where location like '%states'
Order by 1,2

--looking at countries with highest infection rates compared to populations

Select location, population, MAX(total_cases) as HighestInfectionCount,  
MAX(CAST(total_cases AS float)/CAST(population AS float))*100 AS PercentPopulationInfected
From project..CovidDeath
--Where location like '%states'
where continent is not null
Group by location, population
Order by 4 DESC;

--showing countries with highest death count per population

Select location, MAX(CAST(total_deaths AS int)) as total_death
From project..CovidDeath
--Where location like '%states'
where continent is not null
Group by location
Order by 2 DESC;

--Break things down by continent

Select continent, MAX(CAST(total_deaths AS int)) as total_death
From project..CovidDeath
--Where location like '%states'
where continent is not null
Group by continent
Order by 2 DESC;


--showing continent with the highest death count per population

Select continent, MAX(CAST(total_deaths AS int)) as total_death
From project..CovidDeath
--Where location like '%states'
where continent is not null
Group by continent
Order by 2 DESC;

--global numbers

Select date, SUM(new_cases) as total_newcases, SUM(CAST(new_deaths AS int)) as total_newdeaths, 
SUM(CAST(new_deaths AS int))/NULLIF(SUM(new_cases), 0)*100 AS DeathPercentage--total_cases, total_deaths, CAST(total_deaths AS float)/CAST(total_cases AS float)*100 AS DeathPercentage
From project..CovidDeath
--Where location like '%states%'
where continent is not null
Group by date
Order by 1,2

Select SUM(new_cases) as total_cases, SUM(CAST(new_deaths AS int)) as total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage--total_cases, total_deaths, CAST(total_deaths AS float)/CAST(total_cases AS float)*100 AS DeathPercentage
From project..CovidDeath
--Where location like '%states%'
where continent is not null
--Group by date
Order by 1,2

--looking at total population vs vaccinations
--use CTE(common table expression)

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From project..CovidDeath dea
Join project..CovidVaccinations vac
    On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

--TEMP table

DROP Table if exists #PercentPopulationVaccinated --highly recommended statement
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From project..CovidDeath dea
Join project..CovidVaccinations vac
    On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations


USE project
IF OBJECT_ID('dbo.PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW dbo.PercentPopulationVaccinated;
GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
    project..CovidDeath dea
    JOIN project..CovidVaccinations vac 
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL;

Select *
From PercentPopulationVaccinated
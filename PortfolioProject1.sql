select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3, 4

--select data to be used
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1, 2

-- total cases vs total deaths, US
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'DeathPercentage'
from PortfolioProject..CovidDeaths
where location = 'United States'
order by 1, 2

-- total cases vs population, US
select location, date, population, total_cases, (total_cases/population)*100 as 'InfectionPercentage'
from PortfolioProject..CovidDeaths
where location = 'United States'
order by 1, 2

-- countries with highest infection rate
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as 'InfectionPercentage'
from PortfolioProject..CovidDeaths
group by location, population
order by InfectionPercentage desc

-- countries with highest death count
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by TotalDeathCount desc


-- breakdown of death count by continent  
select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc


-- global numbers, per day
select date, sum(new_cases) TotalCases, sum(cast(new_deaths as int)) TotalDeaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as 'DeathPercentage'
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1


-- more data, join tables
select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date


-- total population vs vaccinations 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) AggregateVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- use CTE to find population percentage vaccinated over time
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, AggregateVaccinations)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) AggregateVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (AggregateVaccinations/Population)*100
from PopVsVac


-- temp table to find population percentage vaccinated over time
drop table if exists #PercentPopulationVaccinated 
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
AggregateVaccinations numeric
)
Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) AggregateVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (AggregateVaccinations/Population)*100
from #PercentPopulationVaccinated


-- creating view to store data for visualizations
Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) AggregateVaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
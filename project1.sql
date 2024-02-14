--Cntrl shft rigt- hepsini seçer
--Cntrl z - geri getirir
--totalceses vs totaldeaths
select location, date, total_cases, total_deaths, 
(cast(total_deaths as float)/cast(total_cases as float))*100 as death_percentage from coviddeaths$
--where location like '%states%'
--where continent is not null
order by 1,2


--total cases vs population
select location, date, total_cases, population, 
(cast(total_cases as float)/cast(population as float))*100 as covid_percentage from coviddeaths$
order by 1,2


--countries with highest infection rate vs population
select location, population, max(total_cases) as highestinfectioncount, 
max((cast(total_cases as float)/cast(population as float)))*100 as percentagepopulationinfec from coviddeaths$
group by location, population
order by percentagepopulationinfec desc


--countries with highest death count per population
select location, max(cast(total_deaths as float)) as totaldeathcount 
from coviddeaths$
group by location
order by totaldeathcount desc


--global numbers
select sum(cast(new_cases as float)) as total_cases, sum(cast(new_deaths as float)) as total_deaths, 
sum(cast(new_deaths as float))/sum(cast(new_cases as float))* 100 as deathpercentage
from coviddeaths$
where continent is not null
order by 1,2
select * from covidvactinations$

--sum(convert(vac.new_vaccinations, float))
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,sum(cast(vac.new_vaccinations as float)) OVER 
(partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
--(rollingpeoplevaccinated/population)*100
from coviddeaths$ dea 
join covidvactinations$ vac
	on dea.location=vac.location
	and dea.date=vac.date
where dea.continent is not null
order by 2,3


-- Using CTE(Common Table Expression) to perform Calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) 
OVER (Partition by dea.location Order by dea.location, dea.date) as rollingpeoplevaccinated
From coviddeaths$ dea
Join covidvactinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (rollingpeoplevaccinated/population)*100
From PopvsVac


-- Using Temp Table 

DROP Table if exists #PercentPopulationVaccinated
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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) 
OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

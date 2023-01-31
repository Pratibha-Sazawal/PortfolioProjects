SELECT *
FROM PortfolioProject.dbo.CovidDeaths
Where continent Is Not Null  -- Where it is null, the location is the continent, not country
ORDER BY 3, 4

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY 3, 4

-- Select data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Order By 1,2 --location and date

-- Looking at Total cases vs Total deaths
-- Shows Likelihood of dying if you contract covid in your country

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As DeathPercentage
From PortfolioProject..CovidDeaths
Where location = 'India' And continent Is Not Null
Order By 1,2

-- Looking at Total cases vs Population
-- Shows what percentage of population got covid

Select location, date, population, total_cases, (total_cases/population)*100 As PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where location = 'India' And continent Is Not Null
Order By 1,2

-- Looking at Countries with highest infection rate compared to population

Select location, population, Max(total_cases) As HighestInfectionCount, Max((total_cases/population))*100 As PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By location, population
Order By PercentPopulationInfected Desc

-- Showing Contries with highest death count per population 

Select location, Max(Cast(total_deaths As Int)) As TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By location
Order By TotalDeathCount Desc

-- Showing continents with the highest death count per population

Select continent, Max(Cast(total_deaths As Int)) As TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By continent
Order By TotalDeathCount Desc

-- Global Numbers

Select date, Sum(new_cases) --gives total cases
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By date
Order By 1,2

Select date, Sum(new_cases) As TotalCases, Sum(Cast(new_deaths As Int)) As TotalDeaths, (Sum(Cast(new_deaths As Int))/Sum(new_cases))*100 As DeathPercentage -- new cases is float but new deaths is nvarchar
From PortfolioProject..CovidDeaths
Where continent Is Not Null
Group By date
Order By 1,2

-- Looking at Total population vs Vaccination

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(int, vac.new_vaccinations)) Over (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100 
From PortfolioProject..CovidDeaths As dea
Join PortfolioProject..CovidVaccinations As vac
	On dea.location = vac.location 
	And dea.date = vac.date
Where dea.continent Is Not Null
Order By 2,3

-- To get percentage of population vaccinated, we need to use the new column RollingPeopleVaccinated - Two ways 

-- Use CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
As
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(int, vac.new_vaccinations)) Over (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100 
From PortfolioProject..CovidDeaths As dea
Join PortfolioProject..CovidVaccinations As vac
	On dea.location = vac.location 
	And dea.date = vac.date
Where dea.continent Is Not Null
--Order By 2,3
)

Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Use Temp Table

Drop Table If Exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated --Table name
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(int, vac.new_vaccinations)) Over (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100 
From PortfolioProject..CovidDeaths As dea
Join PortfolioProject..CovidVaccinations As vac
	On dea.location = vac.location 
	And dea.date = vac.date
--Where dea.continent Is Not Null

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualisations

Create View PercentPopulationVaccinated As
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, Sum(Convert(int, vac.new_vaccinations)) Over (Partition By dea.location Order By dea.location, dea.date) As RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100 
From PortfolioProject..CovidDeaths As dea
Join PortfolioProject..CovidVaccinations As vac
	On dea.location = vac.location 
	And dea.date = vac.date
Where dea.continent Is Not Null
--Order By 2,3

Select * 
From PercentPopulationVaccinated

/*
Cleaning Data in SQL Queries
*/

Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

Select SaleDate, Convert(Date, SaleDate)
From PortfolioProject.dbo.NashvilleHousing

Update PortfolioProject.dbo.NashvilleHousing    -- Doesn't update
Set SaleDate = Convert(Date, SaleDate)

Alter Table PortfolioProject.dbo.NashvilleHousing
Add SaleDateConverted Date;

Update PortfolioProject.dbo.NashvilleHousing
Set SaleDateConverted = Convert(Date, SaleDate)

Select SaleDateConverted
From PortfolioProject.dbo.NashvilleHousing

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress Is Null

Select *
From PortfolioProject.dbo.NashvilleHousing
Order By ParcelID         -- When Parcel ID is same for two entries, then Property Address is also same, but Unique ID is different
-- Can populate the null property addresses using this

-- Need to join the table with itself to match the column entries

Select a.ParcelID, a.PropertyAddress, b.ParcelID, B.PropertyAddress
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
On a.ParcelID = b.ParcelID
And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress Is Null

Select a.ParcelID, a.PropertyAddress, b.ParcelID, B.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a   -- Populating a.PropertyAddress where ever it's null by b.PropertyAddress
Join PortfolioProject.dbo.NashvilleHousing b
On a.ParcelID = b.ParcelID
And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress Is Null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
On a.ParcelID = b.ParcelID
And a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress Is Null

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress                    -- Address and City are separated by a comma everywhere
From PortfolioProject.dbo.NashvilleHousing

Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) As Address 
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) As Address
From PortfolioProject.dbo.NashvilleHousing
-- Substring(Where to take string from, starting point index, till where to look)
--charindex gives position of the character
-- -1 because we don't want the comma

-- To separate two values from a column, we need to create two new columns

Alter Table PortfolioProject.dbo.NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

Alter Table PortfolioProject.dbo.NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update PortfolioProject.dbo.NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

Select *
From PortfolioProject.dbo.NashvilleHousing

-- Easier way than Substring

Select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing  -- Address, City and State are separated by commas everywhere

-- Using Parsename - It is only useful with periods (.)
-- Replace (,) with (.)

Select
PARSENAME(Replace(OwnerAddress, ',', '.'), 3)  -- 1 gives the first object separated by comma (state, since Parsename looks backwards)
, PARSENAME(Replace(OwnerAddress, ',', '.'), 2)
, PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
From PortfolioProject.dbo.NashvilleHousing

Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255)

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)

Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitCity Nvarchar(255)

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2) 

Alter Table PortfolioProject.dbo.NashvilleHousing
Add OwnerSplitState Nvarchar(255)

Update PortfolioProject.dbo.NashvilleHousing
Set OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

Select *
From PortfolioProject.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group By SoldAsVacant
Order By 2

Select SoldAsVacant
, Case When SoldAsVacant = 'Y' Then 'Yes'
       When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   End 
From PortfolioProject.dbo.NashvilleHousing

Update PortfolioProject.dbo.NashvilleHousing
Set SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
						When SoldAsVacant = 'N' Then 'No'
						Else SoldAsVacant
						End

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

Select *
From PortfolioProject.dbo.NashvilleHousing

--Removing duplicate rows

Select *,                      -- Partitioning data on things that are unique to each row
	ROW_NUMBER() Over (
	Partition By ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 Order By UniqueID
				 ) row_num     -- row_num = 1 is a particular row and row_num = 2 is its duplicate
From PortfolioProject.dbo.NashvilleHousing
Order By ParcelID
--Where row_num > 1    --Where won't work here, need to create a CTE

  --Creating a CTE - common table expression - Temp table
With RowNumCTE As(
Select *,                      
	ROW_NUMBER() Over (
	Partition By ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 Order By UniqueID
				 ) row_num     
From PortfolioProject.dbo.NashvilleHousing
)
Select *        -- Querying data from this temp table
From RowNumCTE
Where row_num > 1
Order By PropertyAddress  -- These are all duplicates

-- Deleting duplicates
With RowNumCTE As(
Select *,                      
	ROW_NUMBER() Over (
	Partition By ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 Order By UniqueID
				 ) row_num     
From PortfolioProject.dbo.NashvilleHousing
)
Delete 
From RowNumCTE
Where row_num > 1

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From PortfolioProject.dbo.NashvilleHousing

Alter Table PortfolioProject.dbo.NashvilleHousing
Drop Column PropertyAddress, SaleDate, OwnerAddress, TaxDistrict



-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

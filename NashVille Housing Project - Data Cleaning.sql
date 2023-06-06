/*

Cleaning Data in SQL Queries

*/

SELECT *
FROM NashVilleHousing

--- In this dataset, the SaleDate column contains a time element, but this time element is redundant because all times are 00:00, so we will remove this time element.
--- STANDARDIZE DATE FORMAT

SELECT SaleDate1, CONVERT(DATE, SaleDate)
FROM NashVilleHousing;

UPDATE NashVilleHousing
SET SaleDate = CONVERT(DATE, SaleDate);

-- or

ALTER TABLE NashVilleHousing
ADD SaleDate1 DATE;

UPDATE NashVilleHousing
SET SaleDate1 = CONVERT(DATE, SaleDate);

--- The Property Address column contains many missing values, but when observing the dataset, we see that columns with the same ParcelID will have the same Property Address. So we will fill the Property Address columns with the SELF JOIN method.
--- POPULATE PROPERTY ADDRESS DATA

SELECT a.ParcelID
	, a.PropertyAddress
	, b.ParcelID
	, b.PropertyAddress
--	, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashVilleHousing a
JOIN NashVilleHousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
-- WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashVilleHousing a
JOIN NashVilleHousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

---	In the Property Address and Owner Address columns, data such as address, city, and state are in one column and are separated by commas. Therefore, we will separate those data into separate columns using SUBSTRING or PARSENAME.
--- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

-- PropertyAddress

SELECT 
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address1
	, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address2
FROM NashVilleHousing

ALTER TABLE NashVilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashVilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE NashVilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashVilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

-- Check if the data has been updated.

SELECT *
FROM NashVilleHousing

-- OwnerAddress

SELECT OwnerAddress
FROM NashVilleHousing

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashVilleHousing

ALTER TABLE NashVilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashVilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashVilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashVilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashVilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashVilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

-- Check if the data has been updated.

SELECT *
FROM NashVilleHousing

--- The Sold As Vacant column contains 4 different values 'Y', 'N', 'Yes', 'No'. Therefore, we will return only 2 values, 'Yes' and 'No'.
--- CHANGE 'Y' AND 'N' TO 'Yes' AND 'No' IN "Sold as Vacant" FIELD

SELECT DISTINCT(SoldAsVacant)
	, COUNT(SoldAsVacant)
FROM NashVilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
	, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		   WHEN SoldAsVacant = 'N' THEN 'No'
		   ELSE SoldAsVacant 
		   END
FROM NashVilleHousing

UPDATE NashVilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		   WHEN SoldAsVacant = 'N' THEN 'No'
		   ELSE SoldAsVacant 
		   END

--- CHECK FOR DUPLICATES WITH CTE AND ROW_NUMBER

WITH RowNumCTE AS
(
SELECT *
	, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
						 ORDER BY UniqueID) AS row_num
FROM NashVilleHousing)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

--- After checking duplicates, we see that the duplicate rows will have row_num > 1. Therefore, we will delete the rows with row_num > 1 to clean the data.
--- REMOVE DUPLICATES

WITH RowNumCTE AS
(
SELECT *
	, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
						 ORDER BY UniqueID) AS row_num
FROM NashVilleHousing)

DELETE
FROM RowNumCTE
WHERE row_num > 1;

--- Finally, since we have normalized the Sale Date column into a new column, splitting the two Property Address and Owner Address into separate columns, we will delete these three columns.
--- DELETE UNUSED COLUMNS

ALTER TABLE NashVilleHousing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress
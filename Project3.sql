--Hey, welcome,my name is Phi Long
-- You are my third project in my PortfolioProjects in SQL
-- In this project I will clean my data and modified it for more useable purposes.

SELECT *
FROM NashHousing


-- 1.  STANDARDIZE SALEDATE FORMAT

ALTER TABLE NashHousing
	ADD SaleDateUpdated DATE 
UPDATE NashHousing
	SET SaleDateUpdated = CONVERT(DATE, SaleDate)
ALTER TABLE NashHousing
	DROP COLUMN SaleDate

-- POPULATE PROPERTY ADDRESS DATA
-- I FOUND THAT THERE ARE SOME OWNER MAKING TRANSACTIONS MORE THAN ONE TIME, 
--WHICH MEANS THEY USED THE SAME PARCEID MUPTIPLE TRANSACTIONS (EXPLAINED FOR MULTIPLE DIFFERENT UNIQUEID). 
-- HOWEVER, IN OUR DATABASE, WE ONLY RECORED THEIR PROPERTYADRESS IN THEIR FIRST TRANSACTION AND THE OTHERS ARE NOT RECORED, WHICH BRING THE VALLUEs OF NULL.
-- SO, I WILL FILL IN THE NULL VALUEs WITH THE OWNER's INITIAL RECORDED PROPERTY ADDRESS.


SELECT a.ParcelID, b.ParcelID ,a.PropertyAddress, b. PropertyAddress, ISNULL( a.PropertyAddress, b. PropertyAddress ) AS PropertyAddressUpdated
FROM NashHousing a
JOIN NashHousing b
	ON a. ParcelID = b. ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
WHERE a.PropertyAddress IS NULL


UPDATE  a
	SET PropertyAddress = ISNULL( a.PropertyAddress, b. PropertyAddress )
FROM NashHousing a
JOIN NashHousing b
	ON a. ParcelID = b. ParcelID
	AND a.[UniqueID ] <> b. [UniqueID ]
WHERE a.PropertyAddress IS NULL
--tested
SELECT *
FROM NashHousing
WHERE PropertyAddress IS NULL


-- BREAKING ADDRESS INTO INDIVIDUAL COLUMN (ADDRESS, CITY, STATE) -- I will do this in two ways
--#1
SELECT PropertyAddress, 
SUBSTRING(PropertyAddress, 1 , CHARINDEX(',', PropertyAddress)-1)AS PartialAddress,
SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1 ,
LEN(PropertyAddress)) AS City
FROM NashHousing 
#2

SELECT PropertyAddress, 
PARSENAME(REPLACE(PropertyAddress, ',', '.'),2) AS PartialAddress,
PARSENAME(REPLACE(PropertyAddress, ',', '.'),1) AS City
FROM NashHousing 



ALTER TABLE NashHousing
	ADD  PartialAddress NVARCHAR (255), 
		 City NVARCHAR (255)

UPDATE NashHousing
	SET PartialAddress = SUBSTRING(PropertyAddress, 1 , CHARINDEX(',', PropertyAddress)-1),
		City = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1 , LEN(PropertyAddress))


--CHANGE Y AND N TO YES AND NO IN THE SOLD AS VACANT COLUMN AND NULL to NotGivenYet

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashHousing
GROUP BY SoldAsVacant


-- I found that the answer responses are not in the same format so I have to adjust the data into a same format,which is YES and NO only.
SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N'THEN 'No'
		 END
FROM NashHousing

UPDATE NashHousing
	SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
							WHEN SoldAsVacant = 'N'THEN 'No'
							END
UPDATE NashHousing
	SET SoldAsVacant = ISNULL(SoldAsVacant, 'NotGivenYet')

-- REMOVE DUPLICATEs
-- To begin with, I will create a CTE just in case I may need it in the future

WITH temp_1 AS (

SELECT *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, PropertyAddress, LegalReference, SalePrice, SaleDateUpdated
	ORDER BY UniqueID) AS row_num
FROM NashHousing
)
SELECT *
FROM temp_1
WHERE row_num > 1

--I will only remove duplicate in the CT

DELETE 
FROM temp_1
WHERE row_num > 1

--DELETE UNUSED COLUMNs


ALTER TABLE NashHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress,SaleDateUpdated;

-- I understand deletle a large quantity of data is very risky in real-life, however I have to do itfor visualizing purposes.

SELECT *
FROM NashHousing






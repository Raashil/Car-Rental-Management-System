USE CarRentalDB;
GO

-- Create Cars table
CREATE TABLE Cars (
    CarID INT PRIMARY KEY,
    CarName VARCHAR(50),
    Category VARCHAR(20) 
);

-- Insert data into Cars table
INSERT INTO Cars (CarID, CarName, Category) VALUES
(1, 'Car1', 'Sedan'),
(2, 'Car2', 'SUV'),
(3, 'Car3', 'Sedan'),
(4, 'Car4', 'SUV');
GO

-- Create Employees table
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY,
    EmployeeName VARCHAR(50),
    LoginID VARCHAR(50) UNIQUE,
    PasswordHash VARBINARY(64)
);

-- Insert data into Employees table
INSERT INTO Employees (EmployeeID, EmployeeName, LoginID, PasswordHash) VALUES
(123, 'Employee1', 'emp1', HASHBYTES('SHA2_256', 'password1')),
(234, 'Employee2', 'emp2', HASHBYTES('SHA2_256', 'password2')),
(345, 'Employee3', 'emp3', HASHBYTES('SHA2_256', 'password3'));
GO

-- Create Bookings table
CREATE TABLE Bookings (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    CarID INT,
    BookingStartDate DATE,
    BookingEndDate DATE,
    FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    FOREIGN KEY (CarID) REFERENCES Cars(CarID)
);
GO

-- Create CanceledBookings table
CREATE TABLE CanceledBookings (
    CancellationID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT,
    CancellationDate DATE,
    FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID)
);
GO

-- Create Calendar table
CREATE TABLE Calendar (
    Date DATE PRIMARY KEY
);

-- Populate Calendar table with dates
DECLARE @StartDate DATE = '2023-01-01';
DECLARE @EndDate DATE = '2024-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO Calendar (Date) VALUES (@StartDate);
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;
GO

-- Create BookCar procedure
CREATE PROCEDURE BookCar
    @EmployeeID INT,
    @CarID INT,
    @BookingStartDate DATE,
    @BookingEndDate DATE
AS
BEGIN
    -- Checking if the booking dates are valid
    IF @BookingStartDate <= @BookingEndDate
    BEGIN
        -- Checking if the car is available for the specified dates
        IF NOT EXISTS (
            SELECT 1
            FROM Bookings
            WHERE @CarID = CarID
            AND (
                (@BookingStartDate BETWEEN BookingStartDate AND BookingEndDate)
                OR (@BookingEndDate BETWEEN BookingStartDate AND BookingEndDate)
            )
        )
        BEGIN
            DECLARE @NewBookingID INT;

            -- If the car is available, booking it and getting the new BookingID
            INSERT INTO Bookings (EmployeeID, CarID, BookingStartDate, BookingEndDate)
            VALUES (@EmployeeID, @CarID, @BookingStartDate, @BookingEndDate);

            SET @NewBookingID = SCOPE_IDENTITY();

            PRINT 'Booking successful. BookingID: ' + CAST(@NewBookingID AS VARCHAR(10));
        END
        ELSE
        BEGIN
            -- If the car is not available, raising an error
            THROW 50000, 'Car not available for the specified dates.', 1;
        END;
    END
    ELSE
    BEGIN
        -- If the dates are invalid, raising an error
        THROW 50001, 'Invalid booking dates. Start date cannot be after end date.', 1;
    END;
END;
GO

-- Create CancelBooking procedure
CREATE PROCEDURE CancelBooking
    @BookingID INT
AS
BEGIN
    -- Check if the booking exists
    IF EXISTS (SELECT 1 FROM Bookings WHERE BookingID = @BookingID)
    BEGIN
        -- Move the booking to the CanceledBookings table
        INSERT INTO CanceledBookings (BookingID, CancellationDate)
        SELECT BookingID, GETDATE()
        FROM Bookings
        WHERE BookingID = @BookingID;

        -- Delete the entry from the CanceledBookings table if it was successfully moved
        IF @@ROWCOUNT > 0
        BEGIN
            -- Remove the reference from the CanceledBookings table
            DELETE FROM CanceledBookings WHERE BookingID = @BookingID;

            -- Delete the booking from the Bookings table
            DELETE FROM Bookings WHERE BookingID = @BookingID;

            PRINT 'Booking canceled successfully.';
        END
        ELSE
        BEGIN
            PRINT 'Error moving booking to CanceledBookings table.';
        END
    END
    ELSE
    BEGIN
        PRINT 'Booking not found.';
    END
END;
GO

-- Create AuthenticateEmployee procedure
CREATE PROCEDURE AuthenticateEmployee
    @LoginID VARCHAR(50),
    @Password VARCHAR(50)
AS
BEGIN
    DECLARE @EmployeeID INT;

    -- Checking employee credentials
    SELECT @EmployeeID = EmployeeID
    FROM Employees
    WHERE LoginID = @LoginID AND PasswordHash = HASHBYTES('SHA2_256', @Password);

    -- If valid credentials, return the EmployeeName
    IF @EmployeeID IS NOT NULL
    BEGIN
        DECLARE @EmployeeName VARCHAR(50);

        SELECT @EmployeeName = EmployeeName
        FROM Employees
        WHERE EmployeeID = @EmployeeID;

        PRINT 'Login successful. Welcome, ' + @EmployeeName + '.';
    END
    ELSE
        THROW 50000, 'Invalid login credentials.', 1;
END;

-- Create Manager role
CREATE ROLE Manager;
GO

-- Grant permissions to Manager role
GRANT SELECT, INSERT, UPDATE, DELETE ON Cars TO Manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Employees TO Manager;
GRANT SELECT, INSERT, UPDATE, DELETE ON Bookings TO Manager;
GRANT EXECUTE ON BookCar TO Manager;
GRANT EXECUTE ON CancelBooking TO Manager;
GO

-- Add Employee1 to the Manager role
DECLARE @SqlStatement NVARCHAR(MAX);
SET @SqlStatement = 'EXEC sp_addrolemember ''Manager'', ''emp1''';
EXEC sp_executesql @SqlStatement;
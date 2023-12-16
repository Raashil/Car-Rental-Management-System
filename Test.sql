USE CarRentalDB;

-- Test Authenticating an Employee with Valid Credentials
BEGIN TRY
    EXEC AuthenticateEmployee @LoginID = 'emp1', @Password = 'password1';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Test Authenticating an Employee with Invalid Credentials
BEGIN TRY
    EXEC AuthenticateEmployee @LoginID = 'emp1', @Password = 'wrongpassword';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Test Booking a Car
EXEC BookCar @EmployeeID = 123, @CarID = 1, @BookingStartDate = '2023-03-14', @BookingEndDate = '2023-03-20';
EXEC BookCar @EmployeeID = 234, @CarID = 2, @BookingStartDate = '2023-02-03', @BookingEndDate = '2023-02-08';
EXEC BookCar @EmployeeID = 345, @CarID = 3, @BookingStartDate = '2023-02-10', @BookingEndDate = '2023-02-15';
EXEC BookCar @EmployeeID = 123, @CarID = 1, @BookingStartDate = '2023-12-17', @BookingEndDate = '2023-12-25';

-- Test Booking an Unavailable Car
BEGIN TRY
    EXEC BookCar @EmployeeID = 234, @CarID = 1, @BookingStartDate = '2023-03-14', @BookingEndDate = '2023-03-20';
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
END CATCH;

-- Test Canceling a Booking
DECLARE @BookingID INT;

-- Retrieve a BookingID to cancel
SELECT TOP 1 @BookingID = 1 FROM Bookings;

-- Cancel the booking
EXEC CancelBooking @BookingID;
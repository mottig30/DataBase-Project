--fix of Vendors
ALTER TABLE Vendors ALTER COLUMN VendorName varchar (20) not null
ALTER TABLE Vendors ALTER COLUMN  Agent varchar (30) not null
ALTER TABLE Vendors ALTER COLUMN  PhoneNumber varchar (20) not null

--fix of CreditCards
ALTER TABLE CreditCards DROP CONSTRAINT ccv_valid
ALTER TABLE CreditCards ALTER COLUMN CCV Varchar (3) not null
ALTER TABLE CreditCards ADD CONSTRAINT ccv_valid CHECK (CCV LIKE '[0-9][0-9][0-9]')
ALTER TABLE CreditCards ALTER COLUMN CardNumber BigInt not null
ALTER TABLE CreditCards ADD CONSTRAINT valid_number CHECK (CardNumber between 10000000 and 9999999999999999999)

--fix Users
ALTER TABLE Users ADD CONSTRAINT valid_pass CHECK (len(Password) >= 6)

--fix Products
ALTER TABLE Products ADD ProductsInInventory integer;
ALTER TABLE Products ADD Sold integer;

--fix Addresses
DROP TABLE AdditionalAdresses
CREATE TABLE Addresses (
		Email varchar(40) not null FOREIGN KEY REFERENCES Users(Email),
		ZipCode integer not null,
		Number integer not null,
		Country varchar(20) not null,
		City varchar(20) not null,
		Street varchar (30) not null,
		CONSTRAINT pk_adresses PRIMARY KEY (ZipCode, Number)
)

CREATE TABLE ShippingAddressesOfOrder(
		Email varchar(40) not null FOREIGN KEY REFERENCES Users(Email),
		OrderID integer FOREIGN KEY REFERENCES Orders(OrderID),
		ZipCode integer not null,
		Number integer not null,
		CONSTRAINT fk_adresses FOREIGN KEY (ZipCode, Number) REFERENCES Addresses(ZipCode, Number),
		CONSTRAINT pk_adresses_of_order PRIMARY KEY (OrderID)
)

CREATE TABLE BillingAddressesOfOrder(
		Email varchar(40) not null FOREIGN KEY REFERENCES Users(Email),
		OrderID integer FOREIGN KEY REFERENCES Orders(OrderID),
		ZipCode integer not null,
		Number integer not null,
		CONSTRAINT fk_addresses FOREIGN KEY (ZipCode, Number) REFERENCES Addresses(ZipCode, Number),
		CONSTRAINT pk_addresses_of_order PRIMARY KEY (OrderID)
)

---First assignment
--first query, select without nesting
select city, count(city) as [number of customers]
from users
join addresses on
addresses.Email = Users.Email
join Orders on
Orders.Email=Users.Email
where year (Orders.OrderDate) = 2017
group by City
order by [number of customers] DESC     

--second query, select without nesting
select Vendors.VendorName
from Vendors
join Provides
on Provides.VendorID = Vendors.VendorID
join Products on Products.ProductID = Provides.ProductID
where (Products.Sold > 30)
order by VendorName

--first query, nested select
select ProductName 
from Products
where ProductsInInventory <= (select avg (ProductsInInventory) from Products);

--second query, nested select
select ProductName , 100*sold/(
(select sum(Sold) from Products)) as Percentage
from Products 

--first query, update
alter table Models add ActiveModel int not null default(0)
UPDATE Models 
SET ActiveModel = 1
WHERE ModelID in 
(SELECT ModelID
 FROM Includes JOIN orders ON includes.orderId = Orders.orderId 
 WHERE DATEDIFF(year,orderdate,GETDATE()) <= 5)

select * from Models order by ActiveModel DESC 

--second query, delete
Delete from CreditCards
WHERE CreditCards.CardNumber not in 
(SELECT OrderedWith.CardNumber
 FROM OrderedWith JOIN CreditCards ON OrderedWith.CardNumber = CreditCards.CardNumber
 WHERE DATEDIFF(year,CreditCards.ExpirationDate,GETDATE()) >=1       

 ---Second assignemnt
 --view
 drop view [total payment]

create view [total payment]
as
select  email, sum(quantity*Price) as [Total Payment]
from Orders
join Includes on
Orders.OrderID = Includes.OrderID
join models on
models.ModelID = Includes.ModelID
group by Email

select* from [total payment]

--first query, function 1
drop function getUserOrders

create function getUserOrders(@email varchar (50)) 
returns table
as
return (select orderid from Orders where Email=@email)

select * from dbo.getUserOrders('vmhzsqz.rnowaraqxq@example.com')

--second query, function 2
drop function vendorProductsSold

create function vendorProductsSold(@vendorid int )
returns int
as 
begin
	declare @totalProductsSold int
	select  @totalProductsSold= sum(Sold)
	from Vendors
	join Provides
	on Provides.VendorID=Vendors.VendorID
	join Products
	on Products.productid= provides.productid
	join models
	on models.ProductID=products.ProductID
	where(Vendors.vendorid=@vendorid)
	group by Vendors.VendorID
	return @totalProductsSold 
end

select [number of products]= dbo.vendorProductsSold (1)  

--trigger
drop trigger updateProductInInventory

create trigger updateProductInInventory
on includes
for insert
as
update Products
set ProductsInInventory = ProductsInInventory-(select quantity from inserted) 
where Products.productid=(select products.ProductID from products 
join models on Products.ProductID=Models.ProductID 
where(models.modelid=(select ModelID from inserted))

insert into Includes(ModelID,OrderID,Quantity)
values(4,33,3)
select ProductID, ProductsInInventory from Products
select modelid, Productid from Model

--stored procedure
drop procedure update_model_price

create procedure update_model_price (@percent float, @productId int, @modelId int)
as
update Models
set Price = (1 + @percent) *
(select price from Models
where Models.ModelID = @modelId and models.ProductID = @productId)
where (models.modelId = @modelID and models.ProductID = @productId) 

select * from Models
execute update_model_price 10, 109, 1
select * from Models     

---Third Assignment
--first report
drop VIEW [orders per month and product]

CREATE VIEW [orders per month and product]
AS
SELECT Month = Month (Orders.OrderDate), models.ModelID , [Number Of orders] = count(*)
FROM orders JOIN includes ON Includes.orderid = orders.OrderID 
JOIN models ON Includes.ModelID= models.ModelID 
WHERE Orders.OrderDate > DATEADD(year, -1, GETDATE())
GROUP BY Month (Orders.OrderDate), Models.ModelID

Select * from dbo.[orders per month and product]

--second report
drop view [Num of orders per year]

CREATE VIEW [Num of orders per year]
AS
select [Year] = year(orders.OrderDate),[Num of reservations] = count(orders.OrderID)
from Orders 
group by year(Orders.OrderDate)

Select * from dbo.[Num of orders per year]

--third report
drop view [Users Per Countries]

CREATE VIEW [Users Per Countries]
AS
SELECT Country, [Number of Users per country] = count(Country)
FROM addresses
GROUP BY Country

Select * from dbo.[Users Per Countries]

---Fourth Assignment 
--first advanced tool
drop procedure [Give rewards]

create procedure [Give rewards]
as
declare @numberOfOrders int
declare @useremail varchar(50)
declare @totalRewards int
 set @totalRewards = 0

declare userCursor cursor for

select Email, count(orderid) as [number of orders] from Orders 
where (year(orders.OrderDate)>=(year(GETDATE())-10)) 
group by email 

open userCursor
fetch next from userCursor into @useremail,@numberOfOrders
 
 while(@@FETCH_STATUS=0)
 begin 
 if @numberOfOrders = 1
 begin
 update users set [Number of gifts] = [Number of gifts] + 1
 where Email = @useremail
 set @totalRewards = @totalRewards + 1
 end
 if @numberOfOrders >= 2
 begin
  update users set [Number of gifts] = [Number of gifts] + 2
  where Email = @useremail
  set @totalRewards = @totalRewards + 2
 end
 fetch next from usercursor into @useremail, @numberOfOrders
 end

 print 'Total rewards'+ ' ' +cast (@totalRewards as varchar)
 close userCursor
 deallocate userCursor

select * from Users
execute dbo.[Give rewards]
select * from Users

--combination of tools
create procedure NewUser 
 @email varchar (40), @name varchar(30), @pass varchar(10), @address varchar(40)
as insert into Users values (@email, @name,@pass, @address)

create trigger NewUser on Users for insert 
as select case
when 
  select dbo.CountAllGifts() > 50 
 then  set [Number of gifts] = 0
 else 
 set [Number of gifts] = 1
 end

create function CountAllGifts() returns integer
as begin
	declare @counter int = 0
	select  @counter =  sum(users.[Number of gifts]) from Users
	return @counter
end

--nested query report
drop view va

create view va
as
select models.ModelID, avg(quantity * Price) as [Average Sales in Last 5 Years], Price
from Models
join includes
on includes.ModelID = models.ModelID
where Includes.OrderID in (select Orders.OrderID from Orders where 
year(Orders.OrderDate) between (year(GETDATE())-6) and (year(GETDATE())-1))
group by models.modelid,Price

drop view vb

create view vb
as
select models.ModelID, sum(Quantity * Price) as [Sales' Sum This Year] ,sum(Quantity) as [Quantity Sold This Year]
from Models
join includes
on includes.ModelID = models.ModelID
where Includes.OrderID in (select orders.OrderID from Orders where year(orders.OrderDate)=year(getdate())-1)
group by models.ModelID

drop view vc

create view vc
as
select va.ModelID,[Average Sales in Last 5 Years], [Quantity Sold This Year], [Sales' Sum This Year] ,
Difference = [Sales' Sum This Year] - [Average Sales in Last 5 Years] 
from va
right join vb
on va.ModelID = vb.ModelID


Select * from vc                                                                         

---Digital Dashboard
--number of items per order
select orderID, sum(Quantity) from Includes group by OrderID

--average order sum
drop view total_amount_per_order
create view total_amount_per_order as
select includes.OrderID, includes.ModelID, quantity, price, price*quantity as ToatalAmount, orderdate
from includes 
join Models on Includes.ModelID = models.ModelID
join orders on includes.OrderID = Orders.OrderID

select * from total_amount_per_order

--distribution of orders 
select orders.OrderDate, count(orderid) as NumOfOrders
from Orders 
group by OrderDate 
order by NumOfOrders DESC

--popular items this year

create view sales_of_models_per_year
as
select modelId, quantity, year(orders.orderdate)as [Year]
from Includes
join orders on includes.orderid = orders.orderid

--
create view sales_per_vendor
as
select vendorid, products.productid, models.modelid, includes.Quantity, orderdate
from provides 
join products on provides.productid =  products.productid
join Models on models.ProductID = Products.productid
join Includes on includes.modelid = Models.ModelID
join Orders on Includes.OrderID = orders.orderid

--
---select email, TotalPurchases 
drop view total_cost_per_order
create view total_cost_per_order
as
select orders.email, orders.OrderID, totalcost= models.Price*Includes.Quantity, orderdate
from Orders
join Includes on Orders.OrderID= includes.orderid
join models on Includes.ModelID = Models.ModelID

---sum of orders
drop view items_per_order

create view items_per_order
as
select includes.OrderID, sum(quantity) as TotalQuantity, Orders.orderdate 
from includes
join orders on orders.OrderID = Includes.OrderID
group by Includes.orderid, orders.orderdate



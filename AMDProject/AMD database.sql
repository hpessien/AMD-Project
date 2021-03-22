CREATE TABLE public.Pizza_Base
(
    PizzaBase_id serial NOT NULL primary key,
    Pizzabase_flavour text COLLATE pg_catalog."default",
    Pizzabase_price integer
)

--------------------------------------------------------------------

CREATE TABLE public.Size_Pizza
(
    size_pizza_id serial NOT NULL primary key,
    size_pizza integer NOT NULL,
    size_pizza_price integer NOT NULL,
    size_pizza_name text COLLATE pg_catalog."default" NOT NULL
)

--------------------------------------------------------------------

CREATE TABLE public.composed_pizza
(
    pizzabase_id integer NOT NULL,
    size_pizza_id integer NOT NULL,
    ing_id integer NOT NULL,
    comp_pizza_price integer NOT NULL,
    comp_pizza_id serial NOT NULL,
    CONSTRAINT composed_pizza_pkey PRIMARY KEY (comp_pizza_id),
    CONSTRAINT "Pizza_Base_Composed_Pizza_FK" FOREIGN KEY (pizzabase_id)
        REFERENCES public.pizza_base (pizzabase_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT "Size_Pizza_Composed_Pizza_FK" FOREIGN KEY (size_pizza_id)
        REFERENCES public.size_pizza (size_pizza_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

--------------------------------------------------------------------
CREATE TABLE public.ingredient_Items
(
    ing_id serial NOT NULL primary key,
    ing_name text COLLATE pg_catalog."default" NOT NULL,
    ing_isvisible boolean NOT NULL,
    ing_isdeleted boolean NOT NULL,
    ing_price integer NOT NULL,
    ing_region text COLLATE pg_catalog."default" NOT NULL
)
____________________________________________________________________

-------------------------------------------------------------------------------

CREATE TABLE public.Ingredients_Composed_Pizza
(
    comp_pizza_id integer NOT NULL,
    ing_id integer NOT NULL,
    ingredients_composed_pizza_id serial not null primary key,
	
	CONSTRAINT "Ingredients_Ingredients_Composed_Pizza_FK" FOREIGN KEY (ing_id)
    REFERENCES public.ingredient_Items (ing_id) MATCH SIMPLE,
    
)

---------------------------------------------------------------------------------

CREATE TABLE public.Pizza_Ordered
(
    pizza_ordered_id serial NOT NULL Primary key,
    comp_pizza_id integer NOT NULL,
    pizza_ordered_datetime timestamp without time zone NOT NULL,
    CONSTRAINT "composed_pizza_Pizza_Ordered_FK" FOREIGN KEY (comp_pizza_id)
        REFERENCES public.Composed_Pizza (comp_pizza_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

--------------------------------------------------------------------------------
CREATE TABLE public.Ingredient_Supplier
(
    sup_id serial NOT NULL primary key,
    sup_name text COLLATE pg_catalog."default" NOT NULL,
    sup_isvisible boolean NOT NULL,
    sup_isdeleted boolean NOT NULL
)
--------------------------------------------------------------------------------

CREATE TABLE public.Stock
(
    stock_id serial NOT NULL primary key,
    sup_id integer NOT NULL,
    ing_id integer NOT NULL,
    stock_quantity integer NOT NULL,
    CONSTRAINT "Ingredient_items_FK" FOREIGN KEY (ing_id)
        REFERENCES public.ingredient_Items (ing_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT "Supplier_Stock_FK" FOREIGN KEY (sup_id)
        REFERENCES public.Ingredient_Supplier (sup_id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)


------------------------------------------------------------------------------------------------
----Pizza Size insertion Query
------------------------------------------------------------------------------------------------
INSERT INTO public.size_pizza(
	size_pizza, size_pizza_price, size_pizza_name)
	VALUES (7, 2, 'S');
	
	
INSERT INTO public.size_pizza(
	size_pizza, size_pizza_price, size_pizza_name)
	VALUES (10, 4, 'M');
	

INSERT INTO public.size_pizza(
	size_pizza, size_pizza_price, size_pizza_name)
	VALUES (17, 8, 'L');
	
	
INSERT INTO public.size_pizza(
	size_pizza, size_pizza_price, size_pizza_name)
	VALUES (26, 7, 'XL');

--------------------------------------------------------------------------------------------------------
----Types----
--------------------------------------------------------------------------------------------------------
CREATE TYPE public.ingredients_stock AS
(
	id integer,
	name text,
	isvisible boolean,
	isdeleted boolean,
	price integer,
	region text,
	"Stock" integer
);

ALTER TYPE public.ingredients_stock
    OWNER TO postgres;



-- Type: composed_pizza

-- DROP TYPE public.composed_pizza;

CREATE TYPE public.pizza_composed AS
(
	id integer,
	price integer,
	flavour text,
	pizzasize integer,
	ingredients text
);

ALTER TYPE public.pizza_composed
    OWNER TO postgres;


-- Type: ordered_pizza

-- DROP TYPE public.ordered_pizza;

CREATE TYPE public.ordered_pizza AS
(
	flavour text,
	size integer,
	price integer,
	datetime timestamp without time zone,
	ingredients text
);

ALTER TYPE public.ordered_pizza
    OWNER TO postgres;


--------------------------------------------------------------------------------------------------------
----FUNCTIONS----
--------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fun_get_composed_pizza(
	)
    RETURNS SETOF pizza_composed 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
  result_record pizza_composed; --Composite Data type
BEGIN
for result_record in select Composed_Pizza.comp_pizza_id as id, Composed_Pizza.comp_price as price, PizzaBase.pizzabase_flavour as flavour, SizePizza.size_pizza as pizzasize, public.fun_get_ingredients_of_composed_pizza(Composed_Pizza.ing_id) as ingredients 
from Composed_Pizza
INNER JOIN PizzaBase ON PizzaBase.PizzaBase_id = Composed_Pizza.PizzaBase.pizzabase_id
INNER JOIN Size_Pizza ON Size_Pizza.size_pizza_id = Composed_Pizza.size_pizza_id loop
RETURN next result_record;
end loop;
return;
END
$BODY$;

ALTER FUNCTION public.fun_get_composed_pizza()
    OWNER TO postgres;

------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fun_get_ingredients_of_composed_pizza(
	param_ingredient_id integer)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
RETURN (select STRING_AGG(Ingredient_items.ing_name, ',') as Ingredients
from Ingredient_items
inner join Ingredients_Composed_Pizza 
on Ingredients_Composed_Pizza.ing_id = Ingredient_items.ing_id
where Ingredients_Composed_Pizza.comp_pizza_id = param_ingredient_id);
END
$BODY$;

ALTER FUNCTION public.fun_get_ingredients_of_composed_pizza(integer)
    OWNER TO postgres;

------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fun_get_ingredients_with_stock_baker(
	)
    RETURNS SETOF ingredients_stock 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
  result_record ingredients_stock;
BEGIN
for result_record in select Ingredient_Items.ing_id as id, Ingredient_Items.ing_name as name, Ingredient_items.ing_isvisible as isvisible, Ingredient_items.ing_isdeleted as isdeleted,Ingredient_Items.ing_price as price,
Ingredient_Items.ing_region as region, CASE WHEN SUM(Stock.stock_quantity) IS NULL THEN 0 ELSE SUM(Stock.stock_quantity)  END as Stock from Ingredient_items
LEFT JOIN Stock
ON Ingredient_Items.ing_id = Stock.ing_id
GROUP BY Ingredient_Items.ing_id
having Ingredient_Items.ing_isdeleted = false loop
RETURN next result_record;
end loop;
return;
END
$BODY$;

ALTER FUNCTION public.fun_get_ingredients_with_stock_baker()
    OWNER TO postgres;
	
-------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fun_get_ingredients_with_stock_customer(
	)
    RETURNS SETOF ingredients_stock 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
  result_record ingredients_stock;
BEGIN
for result_record in select Ingredient_items.ing_id as id, Ingredient_items.ing_name as name, Ingredient_items.ing_isvisible as isvisible, Ingredient_items.ing_isdeleted as isdeleted,Ingredient_items.ing_price as price,
Ingredient_items.ing_region as region, SUM(Stock.stock_quantity) as Stock from Ingredient_items
inner join Stock
ON Ingredient_items.ing_id = Stock.ing_id
GROUP BY Ingredient_items.ing_id
having Ingredient_items.ing_isvisible = true and Ingredient_items.ing_isdeleted = false and SUM(Stock.stock_quantity) > 0 loop
RETURN next result_record;
end loop;
return;
END
$BODY$;

ALTER FUNCTION public.fun_get_ingredients_with_stock_customer()
    OWNER TO postgres;
	
-----------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fun_get_ordered_pizza(
	)
    RETURNS SETOF ordered_pizza 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
DECLARE
  result_record Ordered_Pizza;
BEGIN
for result_record in select Pizza_Base.pizzabase_flavour as flavour, Size_Pizza.size_pizza as size, Composed_Pizza.comp_pizza_price as price, Pizza_Ordered.pizza_ordered_datetime as datetime,
public.fun_get_ingredients_of_composed_pizza(Composed_Pizza.ing_id) as ingredients
from Composed_Pizza
INNER JOIN Pizza_Base on Pizza_Base.PizzaBase_id = Composed_Pizza.PizzaBase_id
INNER JOIN Size_Pizza on Size_Pizza.size_pizza_id = Composed_Pizza.size_pizza_id
INNER JOIN Pizza_Ordered on Pizza_Ordered.comp_pizza_id = Composed_Pizza.comp_pizza_id loop
RETURN next result_record;
end loop;
return;
END
$BODY$;

ALTER FUNCTION public.fun_get_ordered_pizza()
    OWNER TO postgres;


-- PROCEDURE: public.procaddbasepizza(text, integer)

-- DROP PROCEDURE public.procaddbasepizza(text, integer);

----------------------------------------------------------------------------------------------
--Procedures
----------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE public.pro_add_base_pizza(
	basepizzaname text,
	basepizzaprice integer)
LANGUAGE 'plpgsql'
AS $BODY$
begin
    -- subtracting the amount from the sender's account 
   INSERT INTO Pizza_Base (pizzabase_flavour, pizzabase_price) values (basepizzaname,basepizzaprice);
    commit;
end;
$BODY$;

-- PROCEDURE: public.procaddcomposedpizza(integer, integer, integer, integer[])

-- DROP PROCEDURE public.procaddcomposedpizza(integer, integer, integer, integer[]);

CREATE OR REPLACE PROCEDURE public.pro_add_composed_pizza(
	basepizzaid integer,
	pizzasizeid integer,
	ingreidentid integer,
	ingredientidsforprice integer[])
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE 
finalsum integer;
baseprice integer;
sizeprice integer;
ingredientprice integer;
begin
  baseprice :=(select pizzabase_price from Pizza_Base where pizzabase_id = basePizzaid);
sizeprice :=(select size_pizza_price from Size_Pizza where size_pizza_id = pizzasizeid);
ingredientprice := (select SUM(ing_price) from Ingredient_Items where ing_id =  ANY (ingredientidsforprice));
finalsum := (baseprice + sizeprice + ingredientprice);
--finalsum := 10;
INSERT INTO Composed_Pizza (pizzabase_id, size_pizza_id, ing_id, comp_pizza_price) values (basePizzaid,pizzasizeid,ingreidentid,finalsum);
    commit;
end;
$BODY$;

-- PROCEDURE: public.procaddcomposedpizzaingredients(integer, integer)

-- DROP PROCEDURE public.procaddcomposedpizzaingredients(integer, integer);


CREATE OR REPLACE PROCEDURE public.pro_add_composed_pizza_ingredients(
	composedpizzaid integer,
	ingredientsid integer)
LANGUAGE 'plpgsql'
AS $BODY$
begin
    -- subtracting the amount from the sender's account 
   INSERT INTO Ingredients_Composed_Pizza (comp_pizza_id, ing_id) values (composedpizzaid,ingredientsid);
   UPDATE Stock SET stock_quantity = ((select stock_quantity from Stock where ing_id = ingredientsid and stock_quantity > 0 order by stock_quantity DESC LIMIT 1) - 1) 
   where stock_id = (select stock_id from Stock where ing_id = ingredientsid and stock_quantity > 0 order by stock_quantity DESC LIMIT 1);
   commit;
end;
$BODY$;




CREATE OR REPLACE FUNCTION public.fun_get_ingredients_of_composed_pizza(
	param_ingredient_id integer)
    RETURNS text
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
BEGIN
RETURN (select STRING_AGG(Ingredient_items.ing_name, ',') as Ingredients
from Ingredient_items
inner join Ingredients_Composed_Pizza 
on Ingredients_Composed_Pizza.ing_id = Ingredient_items.ing_id
where Ingredients_Composed_Pizza.comp_pizza_id = param_ingredient_id);
END
$BODY$;

ALTER FUNCTION public.fun_get_ingredients_of_composed_pizza(integer)
    OWNER TO postgres;

--------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE public.pro_add_flavour(										
	flavourname text,
	price integer)
LANGUAGE 'plpgsql'
AS $BODY$
begin
    -- subtracting the amount from the sender's account 
   INSERT INTO pizzaflavour (flavour, price) values (flavourname,price);
    commit;
end;
$BODY$;
----------------------------------------------------------------------------------------


-- PROCEDURE: public.procaddingredient(text, integer, text)

-- DROP PROCEDURE public.procaddingredient(text, integer, text);

CREATE OR REPLACE PROCEDURE public.pro_add_ingredient(
	ingredientname text,
	ingredientprice integer,
	ingredientregion text)
LANGUAGE 'plpgsql'
AS $BODY$
begin
   INSERT INTO Ingredient_Items (ing_name,ing_price,ing_region, ing_isvisible, ing_isdeleted) values (ingredientname,ingredientprice,ingredientregion,true,false);
    commit;
end;
$BODY$;

-- PROCEDURE: public.procaddsize(integer, integer)

-- DROP PROCEDURE public.procaddsize(integer, integer);

CREATE OR REPLACE PROCEDURE public.pro_add_size(
	size integer,
	price integer)
LANGUAGE 'plpgsql'
AS $BODY$
begin
    -- subtracting the amount from the sender's account 
   INSERT INTO Size_Pizza (size_pizza, size_pizza_price) values (size,price);
    commit;
end;
$BODY$;

-- PROCEDURE: public.procaddstock(integer, integer, integer)

-- DROP PROCEDURE public.procaddstock(integer, integer, integer);

CREATE OR REPLACE PROCEDURE public.pro_add_stock(
	supplierid integer,
	ingredientid integer,
	stockid integer)
LANGUAGE 'plpgsql'
AS $BODY$
begin
	INSERT INTO Stock (sup_id, ing_id ,stock_quantity) values (supplierId,ingredientId,stockId);
    commit;
end;
$BODY$;

-- PROCEDURE: public.procaddsupplier(text)

-- DROP PROCEDURE public.procaddsupplier(text);

CREATE OR REPLACE PROCEDURE public.pro_add_supplier(
	suppliername text)
LANGUAGE 'plpgsql'
AS $BODY$
begin
    -- subtracting the amount from the sender's account 
   INSERT INTO Ingredient_Supplier (sup_name, sup_isvisible,sup_isdeleted) values (suppliername,true,false);
    commit;
end;
$BODY$;

-- PROCEDURE: public.procdeleteingredient(integer)

-- DROP PROCEDURE public.procdeleteingredient(integer);

CREATE OR REPLACE PROCEDURE public.pro_delete_ingredient(
	ingredientid integer)
LANGUAGE 'plpgsql'
AS $BODY$
begin
	UPDATE Ingredient_Items
	SET ing_isdeleted = true
	WHERE ing_id = ingredientid;
    commit;
end;
$BODY$;


-- PROCEDURE: public.procdeletesupplier(integer)

-- DROP PROCEDURE public.procdeletesupplier(integer);

CREATE OR REPLACE PROCEDURE public.pro_delete_supplier(
	supplierid integer)
LANGUAGE 'plpgsql'
AS $BODY$
begin
	UPDATE Ingredient_Supplier
	SET sup_isdeleted = true
	WHERE sup_id = supplierid;
    commit;
end;
$BODY$;


-- PROCEDURE: public.procorderpizza(integer)

-- DROP PROCEDURE public.procorderpizza(integer);

CREATE OR REPLACE PROCEDURE public.pro_order_pizza(
	composedid integer)
LANGUAGE 'plpgsql'
AS $BODY$
begin
    -- subtracting the amount from the sender's account 
   INSERT INTO Pizza_Ordered (comp_pizza_id, pizza_ordered_datetime)
	VALUES (composedid,current_timestamp);
    commit;
end;
$BODY$;


-- PROCEDURE: public.procsetingredientvisibility(integer, boolean)

-- DROP PROCEDURE public.procsetingredientvisibility(integer, boolean);

CREATE OR REPLACE PROCEDURE public.pro_set_ingredient_visibility(
	ingredientid integer,
	ingredientvisibility boolean)
LANGUAGE 'plpgsql'
AS $BODY$
begin
	UPDATE Ingredient_Items
	SET ing_isvisible = ingredientvisibility
	WHERE ing_id = ingredientid;
    commit;
end;
$BODY$;



-- PROCEDURE: public.procsetsuppliervisibility(integer, boolean)

-- DROP PROCEDURE public.procsetsuppliervisibility(integer, boolean);

CREATE OR REPLACE PROCEDURE public.pro_set_supplier_visibility(
	supplierid integer,
	suppliervisibility boolean)
LANGUAGE 'plpgsql'
AS $BODY$
begin
	UPDATE Ingredient_Supplier
	SET sup_isvisible = suppliervisibility
	WHERE sup_id = supplierid;
    commit;
end;
$BODY$;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Npgsql;

namespace AMDProject
{

	public partial class MainWindow : Window
	{
		List<ComposePizzaVM> List_ComposedPizzas = new List<ComposePizzaVM>();
		List<IngredientsVM> List_IngredientCustomer = new List<IngredientsVM>();
		List<FlavoursVM> List_AllFlavours = new List<FlavoursVM>();
		List<SupplierVM> List_AllSuppliers = new List<SupplierVM>();
		List<CustomerComposedPizza> List_CustomerComposedPizza = new List<CustomerComposedPizza>();
		List<CustomerOrderedPizza> List_CustomerOrderdPizza = new List<CustomerOrderedPizza>();
		List<IngredientsVM> List_AllIngredients = new List<IngredientsVM>();
		List<SizesVM> List_AllSizes = new List<SizesVM>();
		
		

		Random random = new Random();

		public static string cs = "Host=localhost;Username=postgres;Password=Godkingdom233;Database=AfterChangesFirst";
		NpgsqlConnection con = new NpgsqlConnection(cs);

		public MainWindow()
		{
			InitializeComponent();
			getSuppliers();
			getIngredients();
			getCustomerIngredients();
			getPizzaFlavours();
			getPizzaSizes();
			getOrderedPizzas();
			getComposedPizzas();
		}


		#region CustomerIngredients

		public void getCustomerIngredients()
		{
			
			listViewCustomerIngredients.ItemsSource = null;
			listViewAddIngredients.ItemsSource = null;
			List_ComposedPizzas.Clear();
			List_IngredientCustomer.Clear();
			con.Open();

			string sql = "select * from fun_get_ingredients_with_stock_customer();";
			using var cmd = new NpgsqlCommand(sql, con);

			using NpgsqlDataReader rdr = cmd.ExecuteReader();

			while ( rdr.Read() )
			{

				List_IngredientCustomer.Add(new IngredientsVM()
				{
					Id = rdr.GetInt32(0),
					Name = rdr.GetString(1),
					IsVisible = rdr.GetBoolean(2),
					IsDeleted = rdr.GetBoolean(3),
					Price = rdr.GetInt32(4),
					Region = rdr.GetString(5),
					Stock = rdr.GetInt32(6)
				});
				List_ComposedPizzas.Add(new ComposePizzaVM()
				{
					Id = rdr.GetInt32(0),
					Ingredient = rdr.GetString(1) + " - " + rdr.GetString(5),
					Price = rdr.GetInt32(4)
				});
			}
			listViewAddIngredients.ItemsSource = List_ComposedPizzas;
			listViewCustomerIngredients.ItemsSource = List_IngredientCustomer;
			con.Close();
		}

		private void setOrder_Ingredients(object sender, RoutedEventArgs e)
		{
			var Id = (int)(sender as CheckBox).Tag;
			var isChecked = (bool)(sender as CheckBox).IsChecked;
			List_ComposedPizzas.Where(x => x.Id == Id).FirstOrDefault().isOrdered = isChecked;
		}
		#endregion

		#region Suppliers
		public void getSuppliers()
		{
			comboboxSupplier.Items.Clear();
			listViewSuppliers.ItemsSource = null;
			List_AllSuppliers.Clear();
			con.Open();

			string sql = "SELECT * FROM ingredient_supplier where sup_isdeleted = false";
			using var cmd = new NpgsqlCommand(sql, con);

			using NpgsqlDataReader rdr = cmd.ExecuteReader();

			while ( rdr.Read() )
			{
				List_AllSuppliers.Add(new SupplierVM()
				{
					Id = rdr.GetInt32(0),
					Name = rdr.GetString(1),
					IsVisible = rdr.GetBoolean(2),
					IsDeleted = rdr.GetBoolean(3),
				});
			}
			
			foreach(var supplier in List_AllSuppliers.Where(x=> x.IsVisible == true) )
			{
				comboboxSupplier.Items.Add(supplier.Name);
			}

			listViewSuppliers.ItemsSource = List_AllSuppliers;
			con.Close();
		}

		private void addSupplier(object sender, RoutedEventArgs e)
		{
			string supplierName = txtSupplierName.Text;
			con.Open();
			using ( var cmd = new NpgsqlCommand("CALL pro_add_supplier('"+supplierName+"')", con) )
				cmd.ExecuteNonQuery();
			con.Close();
			getSuppliers();
		}

		private void deleteSupplier(object sender, RoutedEventArgs e)
		{
			var supplierId = (sender as Button).CommandParameter;
			con.Open();

			using ( var cmd = new NpgsqlCommand("CALL pro_delete_supplier('" + supplierId + "')", con) )
				cmd.ExecuteNonQuery();
			con.Close();
			getSuppliers();
		}

		private void SetVisibility_Supplier(object sender, RoutedEventArgs e)
		{
			var Id = (sender as CheckBox).Tag;
			var isChecked = (sender as CheckBox).IsChecked;

			con.Open();

			using ( var cmd = new NpgsqlCommand("CALL pro_set_supplier_visibility('" + Id + "','" + isChecked + "')", con) )
				cmd.ExecuteNonQuery();
			con.Close();
			getSuppliers();
		}
		#endregion

		#region Ingredients
		public void getIngredients()
		{
			comboboxIngredients.Items.Clear();
			listViewIngredients.ItemsSource = null;
			List_AllIngredients.Clear();
			con.Open();

			string sql = "select * from fun_get_ingredients_with_stock_baker();";
			using var cmd = new NpgsqlCommand(sql, con);

			using NpgsqlDataReader rdr = cmd.ExecuteReader();

			while ( rdr.Read() )
			{
				comboboxIngredients.Items.Add(rdr.GetString(1) + "-" +rdr.GetString(5));
				List_AllIngredients.Add(new IngredientsVM()
				{
					Id = rdr.GetInt32(0),
					Name = rdr.GetString(1),
					IsVisible = rdr.GetBoolean(2),
					IsDeleted = rdr.GetBoolean(3),
					Price = rdr.GetInt32(4),
					Region = rdr.GetString(5),
					Stock = rdr.GetInt32(6)
				});
			}

			listViewIngredients.ItemsSource = List_AllIngredients;
			
			con.Close();

			getCustomerIngredients();
		}

		private void addIngredients(object sender, RoutedEventArgs e)
		{
			string ingredientName = txtIngredientName.Text;
			string ingredientRegion = txtIngredientRegion.Text;
			int ingredientPrice = Convert.ToInt32(txtIngredientPrice.Text);
			con.Open();

			using ( var cmd = new NpgsqlCommand("CALL pro_add_ingredient('" + ingredientName + "','" + ingredientPrice + "','" + ingredientRegion + "')", con) )
				cmd.ExecuteNonQuery();

			con.Close();
			getIngredients();
		}

		private void deleteIngredient(object sender, RoutedEventArgs e)
		{
			var ingredientId = (sender as Button).CommandParameter;
			con.Open();

			using ( var cmd = new NpgsqlCommand("CALL pro_delete_ingredient('" + ingredientId + "')", con) )
				cmd.ExecuteNonQuery();

			con.Close();
			getIngredients();
		}

		private void SetVisibility_Ingredients(object sender, RoutedEventArgs e)
		{
			var Id = (sender as CheckBox).Tag;
			var isChecked = (sender as CheckBox).IsChecked;

			con.Open();

			using ( var cmd = new NpgsqlCommand("CALL pro_set_ingredient_visibility('" + Id + "','" + isChecked + "')", con) )
				cmd.ExecuteNonQuery();

			con.Close();
		
			getIngredients();
		}
		#endregion

		#region BasePizza
		public void getPizzaFlavours()
		{
			comboboxBasePizzaCustomer.Items.Clear();
			listViewFlavours.ItemsSource = null;
			List_AllFlavours.Clear();
			con.Open();

			string sql = "SELECT * FROM Pizza_Base";
			using var cmd = new NpgsqlCommand(sql, con);

			using NpgsqlDataReader rdr = cmd.ExecuteReader();

			while ( rdr.Read() )
			{
				comboboxBasePizzaCustomer.Items.Add(rdr.GetString(1));
				List_AllFlavours.Add(new FlavoursVM()
				{
					Id = rdr.GetInt32(0),
					Flavour = rdr.GetString(1),
					Price = rdr.GetInt32(2)
				});
			}
			listViewFlavours.ItemsSource = List_AllFlavours;
			con.Close();

		}

		private void addBasePizza(object sender, RoutedEventArgs e)
		{
			string basePizzaName = txtBasePizza.Text;
			int basePizzaPrice = Convert.ToInt32(txtBasePizzaPrice.Text);
			con.Open();

			using ( var cmd = new NpgsqlCommand("CALL pro_add_base_pizza('" + basePizzaName + "','" + basePizzaPrice + "')", con) )
				cmd.ExecuteNonQuery();

			con.Close();
			getPizzaFlavours();
		}

		#endregion

		#region PizzaSize
		public void getPizzaSizes()
		{
			comboboxPizzaSizeCustomer.Items.Clear();
			List_AllSizes.Clear();
			listViewSizes.ItemsSource = null;
			con.Open();

			string sql = "SELECT * FROM Size_Pizza";
			using var cmd = new NpgsqlCommand(sql, con);

			using NpgsqlDataReader rdr = cmd.ExecuteReader();

			while ( rdr.Read() )
			{
				comboboxPizzaSizeCustomer.Items.Add(rdr.GetInt32(1));
				List_AllSizes.Add(new SizesVM()
				{
					Id = rdr.GetInt32(0),
					Size = rdr.GetInt32(1),
					Price = rdr.GetInt32(2),
					Name = getSizeName(rdr.GetString(3))

					
				});

				if (rdr.GetString(3).Equals("S")) Name = "Small";
			}
			listViewSizes.ItemsSource = List_AllSizes;
			con.Close();

		}

        private string getSizeName(string v)
        {
			if (v.Equals("S")) return "Small";
			else if (v.Equals("M")) return "Medium";
			else if (v.Equals("L")) return "Large";
			else if (v.Equals("XL")) return "Extra Large";
			else return "X";
            
        }
        #endregion

        #region Stock
        private void addStock(object sender, RoutedEventArgs e)
		{
			string ingredientName = comboboxIngredients.Text.Split("-")[0];
			string ingredientRegion = comboboxIngredients.Text.Split("-")[1];
			int supplierId = List_AllSuppliers.Where(x => x.Name == comboboxSupplier.Text).FirstOrDefault().Id;
			int ingredientId = List_AllIngredients.Where(x => x.Name == ingredientName && x.Region == ingredientRegion).FirstOrDefault().Id;
			int stock = Convert.ToInt32(txtStock.Text);

			con.Open();

			using ( var cmd = new NpgsqlCommand("CALL pro_add_stock('" + supplierId + "','" + ingredientId + "','" + stock + "')", con) )
				cmd.ExecuteNonQuery();

			con.Close();
			
			getIngredients();
			getCustomerIngredients();
		}
		#endregion

		#region ComposedPizza
		private void composePizza(object sender, RoutedEventArgs e)
		{
			int randomNumber = random.Next(1000);
			string basePizza = comboboxBasePizzaCustomer.Text;
			int pizzaSize = List_AllSizes.Where(x => x.Size == Convert.ToInt32(comboboxPizzaSizeCustomer.Text)).FirstOrDefault().Id;
			var composedIngredietList = List_ComposedPizzas.Where(x => x.isOrdered == true).ToList();
			List<int> ingredientsList = new List<int>();
			foreach ( var value in composedIngredietList )
			{
				addIngredients_ComposedPizza(randomNumber, value.Id);
				ingredientsList.Add(value.Id);
			}

			int[] ingredientsArray = ingredientsList.ToArray();

			int basePizzaId = List_AllFlavours.Where(x => x.Flavour == basePizza).FirstOrDefault().Id;
			addComposedPizza(basePizzaId, pizzaSize, randomNumber, ingredientsArray);

			getCustomerIngredients();
			getIngredients();
			getComposedPizzas();
		}

		public void addIngredients_ComposedPizza(int randNum, int IngredientId)
		{
			con.Open();
			using ( var cmd = new NpgsqlCommand("CALL pro_add_composed_pizza_ingredients('" + randNum + "','" + IngredientId + "')", con) )
				cmd.ExecuteNonQuery();
			con.Close();
			//getIngredients();
		}

			public void addComposedPizza(int basePizzaId, int pizzaSizeId, int randNum, int[] ingredientsId)
			{
				var concatVal = string.Join(",", ingredientsId);
				con.Open();
				using (var cmd = new NpgsqlCommand("CALL pro_add_composed_pizza('" + basePizzaId + "','" + pizzaSizeId + "','" + randNum + "','{" + concatVal + "}')", con))
					cmd.ExecuteNonQuery();
				con.Close();
			}

		

		public void getComposedPizzas()
		{
			
			listViewCustomerComposedPizzas.ItemsSource = null;
			List_CustomerComposedPizza.Clear();
			con.Open();

			string sql = "select * from fun_get_composed_pizza();";
			using var cmd = new NpgsqlCommand(sql, con);

			using NpgsqlDataReader rdr = cmd.ExecuteReader();

			while ( rdr.Read() )
			{

				List_CustomerComposedPizza.Add(new CustomerComposedPizza()
				{
					id = rdr.GetInt32(0),
					Price = rdr.GetInt32(1),
					Flavour = rdr.GetString(2),
					Size = rdr.GetInt32(3),
					IngredientsName = rdr.GetString(4),
				});
			}
			listViewCustomerComposedPizzas.ItemsSource = List_CustomerComposedPizza;
			con.Close();
		}



		#endregion

		#region orderedPizza
		private void orderPizza(object sender, RoutedEventArgs e)
		{
			var composedpizzaid = (sender as Button).Tag;
			con.Open();
			using (var cmd = new NpgsqlCommand("CALL pro_order_pizza('" + composedpizzaid + "')", con))
			cmd.ExecuteNonQuery();
			con.Close();
            getOrderedPizzas();
        }

        public void getOrderedPizzas()
		{
			listViewOrderedPizzasBaker.ItemsSource = null;
			listViewOrderedPizzasCustomer.ItemsSource = null;
			List_CustomerOrderdPizza.Clear();
			con.Open();

			string sql = "select * from fun_get_ordered_pizza();";
			using var cmd = new NpgsqlCommand(sql, con);

			using NpgsqlDataReader rdr = cmd.ExecuteReader();

			while ( rdr.Read() )
			{
				List_CustomerOrderdPizza.Add(new CustomerOrderedPizza()
				{
					Flavour = rdr.GetString(0),
					Size = rdr.GetInt32(1),
					Price = rdr.GetInt32(2),
					Datetime = Convert.ToString(rdr.GetDateTime(3)),
					Ingredients = rdr.GetString(4)
				});
			}
			listViewOrderedPizzasBaker.ItemsSource = List_CustomerOrderdPizza;
			listViewOrderedPizzasCustomer.ItemsSource = List_CustomerOrderdPizza;
			con.Close();
		}

		#endregion

		private void ComposePizzaSelectionChanged(object sender, SelectionChangedEventArgs e)
		{

		}

        private void Btn_Exit_Customer_Click(object sender, RoutedEventArgs e)
        {
			//Application.Current.Shutdown();
			Environment.Exit(0);
        }

        private void Btn_Exit_Baker_Click(object sender, RoutedEventArgs e)
        {
			//getOrderedPizzas();
			Environment.Exit(0);
			//Application.Current.Shutdown();
		}

        private void TabControl_SelectionChanged()
        {

        }
    }
}

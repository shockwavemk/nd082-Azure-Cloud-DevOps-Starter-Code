# #!/usr/bin/env python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.common.by import By
import logging

# Start the browser and login with standard_user
def functional_ui_test(user, password):
    logging.basicConfig(filename='selenium.log', level=logging.DEBUG, format='%(asctime)s %(levelname)s %(message)s')
    logging.info('Starting the browser...')
    
    # --uncomment when running in Azure DevOps.
    options = ChromeOptions()
    options.add_argument('--no-sandbox')
    options.add_argument("--headless") 
    options.add_argument("--remote-debugging-port=9222")
    driver = webdriver.Chrome(options=options)
    
    logging.info('Browser started. Navigating to the demo page to login.')
    driver.get('https://www.saucedemo.com/')
    driver.find_element(By.CSS_SELECTOR,"input[id='user-name']").send_keys(user)
    driver.find_element(By.CSS_SELECTOR,"input[id='password']").send_keys(password)
    driver.find_element(By.CSS_SELECTOR,"input[id='login-button']").click()
    xpath_content_div = "div[id='page_wrapper'] > div[id='contents_wrapper']"
    results = driver.find_element(By.CSS_SELECTOR,xpath_content_div + " > div[class='header_container'] > div[class='header_secondary_container'] > span").text
    assert "Products" in results
    logging.info("Logged in as " + user)

    logging.info("Add items")
    xpath_inventory_item = "//*[@id='inventory_container']/*[@class='inventory_list']/div[@class='inventory_item']"
    inventory_items = driver.find_elements(By.XPATH,xpath_inventory_item)
    assert len(inventory_items) == 6
    logging.info("Found 6 product items.")    
    
    for item in inventory_items:
        product_item_name = item.text.split('\n',1)[0]
        item.find_element(By.XPATH,"//button[contains(text(),'Add to cart')]").click()
        logging.info("Succesfully added to shopping cart: " + product_item_name)
        
    xpath_shopping_cart_container = "//*[@id='shopping_cart_container']"
    xpath_shopping_cart_badge = xpath_shopping_cart_container + "//span[@class='shopping_cart_badge']"
    total_items = driver.find_element(By.XPATH,xpath_shopping_cart_badge).text
    assert '6' == total_items
    logging.info("Added 6 items to cart")

    logging.info("Remove items")
    driver.find_element(By.XPATH,xpath_shopping_cart_container).click()
    xpath_cart_title = "//*[@id='header_container']/div[@class='header_secondary_container']/span"
    cart_title = driver.find_element(By.XPATH,xpath_cart_title).text
    assert 'Your Cart' in cart_title
    logging.info("Loaded shopping cart page")
    xpath_cart_item_remove_buttons = "//*[@id='cart_contents_container']//div[@class='cart_list']//div[@class='cart_item']"
    remove_item_buttons = driver.find_elements(By.XPATH,xpath_cart_item_remove_buttons)
    
    for remove_button in remove_item_buttons:
        item_name = remove_button.find_element(By.XPATH,"//*[@class='inventory_item_name']").text
        remove_button.find_element(By.XPATH,"//button[text()='Remove']").click()
        logging.info("Removed item from cart: " + item_name)
        
    total_items = driver.find_elements(By.XPATH,xpath_shopping_cart_badge)
    assert 0 == len(total_items)
    logging.info("Removed all items from cart")

functional_ui_test('standard_user', 'secret_sauce')

WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        i.i_product_name,
        i.i_category,
        p.p_promo_name,
        p.p_channel_radio,
        p.p_channel_press,
        t.t_time,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 1000
      AND cs.cs_sales_price BETWEEN 10 AND 100
      AND t.t_time IN (1, 5, 13)
      AND p.p_channel_radio = 'N'
      AND p.p_channel_press = 'N'
      AND inv.inv_quantity_on_hand > 0
      AND hd_bill.hd_income_band_sk = 5
),
high_profit_items AS (
    SELECT DISTINCT cs_item_sk
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax > 20000
),
promo_items AS (
    SELECT DISTINCT p_item_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
),
target_items AS (
    SELECT cs_item_sk
    FROM high_profit_items
    EXCEPT
    SELECT p_item_sk FROM promo_items
)
SELECT
    sd.cs_order_number,
    sd.i_product_name,
    sd.i_category,
    sd.cs_quantity,
    sd.cs_sales_price,
    sd.cs_net_paid_inc_ship_tax,
    sd.t_time,
    CASE
        WHEN sd.cs_net_paid_inc_ship_tax > 15000 THEN 'HIGH'
        WHEN sd.cs_net_paid_inc_ship_tax > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    ROW_NUMBER() OVER (PARTITION BY sd.i_category ORDER BY sd.cs_net_paid_inc_ship_tax DESC) AS category_rank,
    RANK() OVER (ORDER BY sd.cs_net_paid_inc_ship_tax DESC) AS overall_rank
FROM sales_data sd
WHERE sd.cs_item_sk IN (SELECT cs_item_sk FROM target_items)
  AND NOT EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = sd.cs_item_sk
          AND p2.p_start_date_sk <= sd.cs_sold_date_sk
          AND p2.p_end_date_sk >= sd.cs_sold_date_sk
    )
ORDER BY overall_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY

WITH sales_inv AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_quantity,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN inventory inv
        ON ss.ss_item_sk = inv.inv_item_sk
       AND ss.ss_sold_date_sk = inv.inv_date_sk
    WHERE inv.inv_quantity_on_hand > 0
      AND ss.ss_ext_discount_amt > 0
),
agg AS (
    SELECT
        ib.ib_income_band_sk,
        si.inv_warehouse_sk,
        SUM(si.ss_net_profit) AS total_net_profit,
        SUM(si.ss_ext_sales_price) AS total_sales,
        AVG(si.ss_ext_discount_amt) AS avg_discount,
        SUM(si.inv_quantity_on_hand) AS total_inventory
    FROM sales_inv si
    JOIN income_band ib
        ON si.ss_net_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    GROUP BY ib.ib_income_band_sk, si.inv_warehouse_sk
)
SELECT
    ib_income_band_sk,
    inv_warehouse_sk,
    total_net_profit,
    total_sales,
    avg_discount,
    total_inventory,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY ib_income_band_sk, profit_rank

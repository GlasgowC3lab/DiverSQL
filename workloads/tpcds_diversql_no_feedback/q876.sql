WITH catalog_agg AS (
    SELECT
        cs_item_sk,
        cs_sold_time_sk,
        SUM(cs_ext_sales_price) AS cat_sales,
        SUM(cs_net_profit) AS cat_profit
    FROM tpcds.catalog_sales
    GROUP BY cs_item_sk, cs_sold_time_sk
)
SELECT
    s.s_store_name,
    i.i_category,
    t_store.t_hour,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ca.cat_sales) AS catalog_sales_total,
    SUM(inv1.inv_quantity_on_hand) AS qty_wh1,
    SUM(inv2.inv_quantity_on_hand) AS qty_wh2,
    COUNT(DISTINCT ss.ss_ticket_number) AS txn_count
FROM catalog_agg ca
JOIN tpcds.catalog_sales cs
    ON cs.cs_item_sk = ca.cs_item_sk
   AND cs.cs_sold_time_sk = ca.cs_sold_time_sk
JOIN tpcds.item i
    ON i.i_item_sk = cs.cs_item_sk
JOIN tpcds.customer_address ca_bill
    ON ca_bill.ca_address_sk = cs.cs_bill_addr_sk
JOIN tpcds.customer_address ca_ship
    ON ca_ship.ca_address_sk = cs.cs_ship_addr_sk
JOIN tpcds.inventory inv1
    ON inv1.inv_item_sk = i.i_item_sk
JOIN tpcds.inventory inv2
    ON inv2.inv_item_sk = i.i_item_sk
JOIN tpcds.store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.time_dim t_store
    ON t_store.t_time_sk = ss.ss_sold_time_sk
JOIN tpcds.customer_address ca_ss
    ON ca_ss.ca_address_sk = ss.ss_addr_sk
JOIN tpcds.store s
    ON s.s_store_sk = ss.ss_store_sk
JOIN tpcds.time_dim t_cat
    ON t_cat.t_time_sk = ca.cs_sold_time_sk
WHERE i.i_category = 'Sports'
GROUP BY s.s_store_name, i.i_category, t_store.t_hour
HAVING SUM(ss.ss_ext_sales_price) > 1000
ORDER BY store_sales_total DESC
LIMIT 100

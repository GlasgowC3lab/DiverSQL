WITH filtered_union AS (
    SELECT
        c.c_customer_id AS customer_id,
        w.w_warehouse_name AS warehouse_name,
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price AS sales_amount,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss
    FROM customer c
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE c.c_first_sales_date_sk = 2450391
      AND ws.ws_net_paid_inc_ship > 1500
      AND w.w_state = 'CA'

    UNION DISTINCT

    SELECT
        c.c_customer_id AS customer_id,
        w.w_warehouse_name AS warehouse_name,
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price AS sales_amount,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss
    FROM customer c
    JOIN web_sales ws ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
    WHERE c.c_first_shipto_date_sk = 2451855
      AND ws.ws_ext_sales_price >= 2000
      AND w.w_zip = '55709'
)
SELECT
    customer_id,
    warehouse_name,
    COUNT(DISTINCT order_number) AS order_cnt,
    SUM(sales_amount) AS total_sales,
    SUM(return_amount) AS total_returns,
    SUM(net_loss) AS total_net_loss,
    AVG(sales_amount) AS avg_sales,
    MIN(sales_amount) AS min_sales,
    MAX(sales_amount) AS max_sales
FROM filtered_union fu
WHERE fu.sales_amount > (
    SELECT AVG(ws_ext_sales_price) FROM web_sales
)
GROUP BY customer_id, warehouse_name
ORDER BY total_sales DESC
LIMIT 100

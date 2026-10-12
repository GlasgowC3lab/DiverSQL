WITH agg1 AS (
    SELECT
        s.s_store_name AS store_name,
        p.p_promo_name AS promo_name,
        d.d_year AS year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(sr.sr_return_amt) AS total_store_return,
        SUM(wr.wr_return_amt) AS total_web_return,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_cost > 500
      AND s.s_tax_percentage < 0.05
      AND cs.cs_quantity > 1
      AND cs.cs_ext_discount_amt > 0
      AND ca_bill.ca_state = 'CA'
      AND wp.wp_type = 'Content'
      AND ws.web_tax_percentage = 0.04
    GROUP BY GROUPING SETS (
        (s.s_store_name, p.p_promo_name, d.d_year),
        (s.s_store_name, d.d_year),
        (p.p_promo_name, d.d_year)
    )
),
agg2 AS (
    SELECT
        store_name,
        promo_name,
        year,
        total_sales - total_store_return - total_web_return AS net_amount,
        orders
    FROM agg1
    WHERE total_sales > 1000
)
SELECT store_name, promo_name, year, net_amount, orders
FROM agg2
WHERE net_amount > 0
EXCEPT
SELECT store_name, promo_name, year, net_amount, orders
FROM agg2
WHERE net_amount < 0
ORDER BY net_amount DESC
LIMIT 100

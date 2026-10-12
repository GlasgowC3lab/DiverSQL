WITH sales_in_period AS (
    SELECT
        ss_sold_date_sk,
        ss_store_sk,
        ss_customer_sk,
        ss_item_sk,
        ss_net_profit,
        ss_ext_discount_amt,
        ss_quantity,
        ss_ticket_number
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451409 AND 2452186
      AND ss_store_sk IN (34, 574, 211)
      AND ss_quantity > 0
),
website_active AS (
    SELECT
        web_site_sk,
        web_name,
        web_city,
        web_state,
        web_country,
        web_open_date_sk,
        web_close_date_sk
    FROM web_site
    WHERE web_country = 'USA'
      AND web_state IN ('CA', 'TX', 'NY')
),
aggregated AS (
    SELECT
        w.web_site_sk,
        w.web_name,
        w.web_city,
        SUM(s.ss_net_profit) AS total_net_profit,
        AVG(s.ss_ext_discount_amt) AS avg_discount_amt,
        SUM(s.ss_quantity) AS total_quantity,
        COUNT(DISTINCT s.ss_ticket_number) AS distinct_tickets
    FROM sales_in_period s
    JOIN website_active w
        ON s.ss_sold_date_sk BETWEEN w.web_open_date_sk
            AND COALESCE(w.web_close_date_sk, 9999999)
    GROUP BY w.web_site_sk, w.web_name, w.web_city
    HAVING SUM(s.ss_net_profit) > 1000
)
SELECT
    a.*,
    RANK() OVER (ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 10

WITH
    ss_sample AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
    ),
    joined AS (
        SELECT
            ss.ss_ticket_number,
            d1.d_year AS sales_year,
            t1.t_hour AS sold_hour,
            s1.s_store_name,
            ca1.ca_city AS sales_city,
            ss.ss_net_paid,
            sr.sr_return_quantity,
            cc.cc_name,
            d3.d_year AS cc_closed_year,
            ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_net_paid DESC) AS sales_rank
        FROM ss_sample ss
        FULL OUTER JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
           AND ss.ss_item_sk      = sr.sr_item_sk
        JOIN date_dim d1
            ON ss.ss_sold_date_sk = d1.d_date_sk
        JOIN time_dim t1
            ON ss.ss_sold_time_sk = t1.t_time_sk
        JOIN store s1
            ON ss.ss_store_sk = s1.s_store_sk
        JOIN customer_address ca1
            ON ss.ss_addr_sk = ca1.ca_address_sk
        JOIN household_demographics hd1
            ON ss.ss_hdemo_sk = hd1.hd_demo_sk
        JOIN income_band ib1
            ON hd1.hd_income_band_sk = ib1.ib_income_band_sk
        LEFT JOIN call_center cc
            ON cc.cc_closed_date_sk = d1.d_date_sk
        LEFT JOIN date_dim d3
            ON cc.cc_closed_date_sk = d3.d_date_sk
        WHERE d1.d_year = 2001
    ),
    filtered AS (
        SELECT *
        FROM joined
        WHERE sales_rank <= 3
    ),
    sales_keys AS (
        SELECT ss_ticket_number FROM store_sales
    ),
    returns_keys AS (
        SELECT sr_ticket_number AS ss_ticket_number FROM store_returns
    ),
    diff_keys AS (
        SELECT ss_ticket_number FROM sales_keys
        EXCEPT
        SELECT ss_ticket_number FROM returns_keys
    )
SELECT
    f.sales_year,
    f.s_store_name,
    f.sales_city,
    f.sold_hour,
    SUM(f.ss_net_paid)               AS total_net_paid,
    COUNT(DISTINCT f.ss_ticket_number) AS unique_tickets,
    COUNT(*) FILTER (WHERE f.sr_return_quantity IS NOT NULL) AS returns_count
FROM filtered f
GROUP BY f.sales_year, f.s_store_name, f.sales_city, f.sold_hour
HAVING SUM(f.ss_net_paid) > 1000
UNION DISTINCT
SELECT
    d.d_year        AS sales_year,
    s.s_store_name,
    ca.ca_city      AS sales_city,
    t.t_hour        AS sold_hour,
    SUM(ss.ss_net_paid)               AS total_net_paid,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
    0                                 AS returns_count
FROM store_sales ss
JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t      ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s         ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
WHERE d.d_year = 2002
GROUP BY d.d_year, s.s_store_name, ca.ca_city, t.t_hour
ORDER BY total_net_paid DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY

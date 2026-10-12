WITH sales AS (
    SELECT
        d.d_year,
        ca.ca_state,
        cs.cs_net_profit AS profit,
        cs.cs_sales_price AS sales,
        cc.cc_name AS channel_name
    FROM
        catalog_sales cs
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN
        customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN
        call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2002
        AND cs.cs_net_profit > 0
    UNION ALL
    SELECT
        d.d_year,
        ca.ca_state,
        ss.ss_net_profit AS profit,
        ss.ss_sales_price AS sales,
        st.s_store_name AS channel_name
    FROM
        store_sales ss
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN
        customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN
        store st ON ss.ss_store_sk = st.s_store_sk
    WHERE
        d.d_year BETWEEN 1998 AND 2002
        AND ss.ss_net_profit > 0
)
SELECT
    d_year,
    ca_state,
    SUM(profit) AS total_profit,
    SUM(sales) AS total_sales,
    COUNT(*) AS transactions,
    AVG(profit) AS avg_profit,
    MAX(profit) AS max_profit
FROM
    sales
GROUP BY
    d_year,
    ca_state
ORDER BY
    total_sales DESC
LIMIT 100

SELECT *
FROM (
    SELECT
        c.c_salutation,
        c.c_birth_country,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_promo_sk IN (1170, 1178)
      AND cs.cs_ext_list_price > 2000
    GROUP BY CUBE (c.c_salutation, c.c_birth_country)

    UNION ALL

    SELECT
        c.c_salutation,
        c.c_birth_country,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(cs.cs_net_paid_inc_tax) > 5000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_promo_sk IN (1196, 1327)
      AND cs.cs_ext_list_price < 3000
    GROUP BY CUBE (c.c_salutation, c.c_birth_country)
) AS combined
LIMIT 100

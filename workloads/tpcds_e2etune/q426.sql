WITH aggregated AS (
    SELECT
        cc.cc_city,
        r.r_reason_desc,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cs.cs_ext_discount_amt > 0
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cc.cc_city, r.r_reason_desc
    HAVING COUNT(*) > 10
)
SELECT
    cc_city,
    r_reason_desc,
    distinct_customers,
    total_discount,
    avg_discount,
    RANK() OVER (PARTITION BY cc_city ORDER BY total_discount DESC) AS discount_rank
FROM aggregated
ORDER BY total_discount DESC
LIMIT 100

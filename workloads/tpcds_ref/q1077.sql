select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 945 and 945+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'orchid') and 
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'rosy') and
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'maroon') and
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'pale') and
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peach' or i_color = 'moccasin') and 
        (i_units = 'Box' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'seashell') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'honeydew') and
        (i_units = 'Tbl' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'navajo') and
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100

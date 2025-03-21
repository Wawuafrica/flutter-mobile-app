import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class ReviewComponent extends StatelessWidget {
  const ReviewComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          width: 0.5,
          color: const Color.fromARGB(255, 181, 181, 181),
        ),
        borderRadius: BorderRadius.circular(10.0),
      ),
      width: double.infinity,
      height: 180,
      padding: EdgeInsets.all(20.0),
      child: Column(
        spacing: 10.0,
        children: [
          Row(
            spacing: 10.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: Image.asset('assets/images/section/programming.png'),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5.0,
                  children: [
                    Text('Micheal John'),
                    Row(
                      spacing: 2.0,
                      children: [
                        Icon(Icons.star, size: 17, color: wawuColors.primary),
                        Icon(Icons.star, size: 17, color: wawuColors.primary),
                        Icon(Icons.star, size: 17, color: wawuColors.primary),
                        Icon(Icons.star, size: 17, color: wawuColors.primary),
                        Icon(Icons.star, size: 17, color: wawuColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '20/12/2025',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut tellus ipsum, sodales non rhoncus sit amet, viverra eu mi. Curabitur congue condimentum turpis sit amet maximus. Donec elementum ligula tellus, et blandit tortor maximus nec. Nullam rutrum rhoncus metus, quis aliquam augue hendrerit cursus. Proin mollis eget massa sed scelerisque. Nullam laoreet dictum viverra. Nullam ornare, urna in mattis pulvinar, felis elit convallis orci, at molestie purus eros id nisl. Nullam maximus sed neque ac pellentesque. Ut pretium felis risus, a gravida tellus feugiat at. Nullam bibendum mi vel arcu condimentum, sed suscipit dui sollicitudin. Nam',
            style: TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

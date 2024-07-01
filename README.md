# Seat in Shade

Discover the perfect shady seat 😎.

This app allows you to input your starting and ending locations and then calculate the route and the sun's direction for your journey if you start now.

<table>
  <tr>
    <td>
      <img src="https://github.com/rational-kunal/SeatInShade/assets/28783605/3880bc48-79fc-42a1-8dd8-3de7d6f86c15" alt="SeatInShadeDemo" width="400"/>
    </td>
    <td>
      <img src="https://github.com/rational-kunal/SeatInShade/assets/28783605/76a0b98a-0ea8-40d6-b1ee-c929b00ca45b" alt="SeatInShadeDemo" width="400"/>
    </td>
  </tr>
</table>

## How It Works

The app leverages MapKit to display the map with annotations and the route. It assists with searching for locations and calculating the route and estimated travel time.

### Internally,
1. **Location Search**: Use the location picker to search for the starting and ending locations. This uses MapKit APIs for autocomplete functionality.
2. **Route Calculation**: Using MapKit, calculate the route and the estimated travel time between the selected locations.
3. **Route Segmentation**: Split the route into segments and determine the coordinates of each point.
4. **Sun Direction**: Obtain the sun's direction at each point along the route.

Built with SwiftUI and MapKit, the app also utilizes SwiftAA for astronomical calculations.

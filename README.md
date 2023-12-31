# Frequency and Power Prediction System
Frequency and Power Prediction System is a forecasting tool made with [MATLAB](https://www.mathworks.com/products/matlab.html) to predict frequency of the electrical grid and the scheduled power generation of the power plant.
The real time frequency data, scheduled power data and actual power data is extracted from [UP load despatch centre](https://www.upsldc.org/real-time-data).

![Image](https://github.com/Nesasio/Scheduled-Power-Prediction-System/assets/110229836/1580873a-3168-4ea5-afea-554567a9e657)
*Prediction System User Interface*

In context of a thermal power plant, scheduled power is the power generation which is to be maintained by the plant in accordance with the power demand, costs and various other factors. This scheduled power value for a particular time in a day is assigned to the power plant around 2 blocks in advance. A block in this context is a period of 15 minutes starting from 0000 hours, meaning the block number is 1 from 0000 to 0015 hours on any particular day. This prediction tool therefore, predicts the scheduled power value of the next block and the n+3rd block to aid in better power management of the power plant.

The real time data updates every 15 minutes and this system takes a few data points before starting predictions. As soon as few data points are collected, the prediction will start and the system will plot the predicted values of the next block and the n+3rd block every 15 minutes.

## User Interface
The user interface displays an interactive table which shows the values of frequency, power data and block number along with the predicted suggestion for the next block which updates in real time every 15 minutes.
The real time graphs are also displayed which shows current as well as predicted values. Graphs can be cycled between power data and frequency data from the tab group.
The current value and the immediate next prediction values are shown on top.
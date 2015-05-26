# Environmental Statistics and Modeling, Methods and Algorithms
This is a collection of environmental models useful in academic research, consultancy, policy making etc. The fundamentals of these models will be briefly introduced together with their documentation and tutorials. Some of my early work involved the use of these models are also posted here. I try to cover all types of model useful in environmental research. Though this is not the only or the last repository, I will put all my effort to make it one of the best. In ideal case, I will create an example with detailed explanation in Python notebook. 

### Table of Contents
* [Climate](#climate)
* [Meteorology/Weather](#meteorology-weather)
* [Air Quality](#air-quality)
* [Hydrology](#hydrology)
* [Water Quality](#water-quality)
* [Management](#energy)
* [Data-Driven](#data-driven)
* [Sample Works](#sample-works)

### Mathematical Simulation
Models appeared in this section are mainly based on rules of physics such as mass balance and energy balance. 
#### Climate
* [Box Models](http://rstb.royalsocietypublishing.org/content/royptb/365/1545/1349.full.pdf) - A paper published by Johns Hopkins University 
* [Zero-dimensional Models](http://icp.giss.nasa.gov/education) - radiative balance
* Radiative-Convective Models
* [General Circulation Models (GCMs)](http://en.wikipedia.org/wiki/General_Circulation_Model) - a mathematical model of the general circulation of a planetary atmosphere or ocean and based on the Navier–Stokes equations on a rotating sphere with thermodynamic terms for various energy sources (radiation, latent heat).
 * [GFDL CM 2.x](http://nomads.gfdl.noaa.gov/CM2.X/) - Geophysical Fluid Dynamics Laboratory Coupled Model, version 2.X, is a coupled atmosphere-ocean general circulation model (AOGCM) developed at the NOAA Geophysical Fluid Dynamics Laboratory in the United States. 
* [pyCMBS](https://github.com/pygeo/pycmbs) - A neat solution for climate data from Python

 # Additional Resources
> [A very good course on climate modeling](https://github.com/brian-rose/ClimateModeling_courseware/blob/master/index.ipynb)

#### Meteorology/Weather
* [Weather Research Forecasting (WRF) Model](http://www.wrf-model.org/index.php) - "a next-generation mesoscale numerical weather prediction system designed for both atmospheric research and operational forecasting needs."

#### Air Quality  
* Fixed Box Models 
* [Dispersion Models](http://en.wikipedia.org/wiki/List_of_atmospheric_dispersion_models) - A list of atmospheric dispersion models
* Photochemical Models
* Receptor Models
* Back-Trajactory Models

#### Hydrology
* Stochastic Models
* Process-Based Models
* 

#### Water Quality
* Aquasim
* 

#### Management
* Linear Programming
* Nonlinear Programming
* Integer Programming
* Stochastic Programming
* Dynamic Programming
* [Partially Observable Markov Decison Process](http://www.pomdp.org/tutorial/) - POMDP 


## Data-Driven
Models appeared in this section are based on statistical learning and machine learning theory, where the performance of model depends heavily on the availability of data. 

#### Regression Models
* Linear Regression
* Generalized Linear Models (GLMs) 
* Generalized Additive Models (GAMs)

#### Dimension Reduction
* RIDGE/LASSO
* Principle Component Analysis (PCA)

#### Classification Models
* Classification and Regression Trees (CART)
* Support Vector Machine (SVM) 
* K-Nearest Neighbour (kNN)
* K-Mean Clustering 

#### Black-boxed Models
* Random Forest
* Artificial Neural Networks (ANN)
* [Baysian Additive Regression Trees (BART)](http://www-stat.wharton.upenn.edu/~edgeorge/Research_papers/BART%20June%2008.pdf)

## Additional Resources
> [Courses](http://nbviewer.ipython.org/github/jakevdp/sklearn_pycon2015/blob/master/notebooks/Index.ipynb)

#### Time Series Models
* Autoregressive Integrated Moving Average Model (ARIMA)

#### Spatial Models
* Quadrat Counting
* Density Estimation
* Inverse Distance Weight 
* Krigging

#### Raster Analysis 
* Normalized Difference Vegetation Index (NDVI)

### Sample Works
A collection of python notebook will be created from my previous study:
* Undergraduate - Environmental Science, _Hong Kong_
* Graduate - Environmental Engineering and Management, _Hong Kong_
* Graduate - Geography and Environmental Engineering, _Maryland_

 * [Weighted Sum Application](http://nbviewer.ipython.org/github/kairusann/envstat/blob/master/notebook/primer.ipynb)

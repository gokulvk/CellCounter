   dir = getDirectory("Choose a folder");
   setBatchMode(true);

   //data holds number of cells and names holds name of image
   var data = newArray(0);
   var names = newArray(0);

   //variables that store custom settings for image analysis
   var numChannels = 4;
   var channel1 = 2;
   var channel2 = 3;
   var name1 = "gfp"
   var name2 = "ki67"
   var slidesPerSample = 3;
   var minThreshold = 25;
   var maxThreshold = 255;
   var numSmooth = 1;
   var numSharpen = 0;
   var minSize = "4";

   //asks user to put in info of image
   Dialog.create("Channels for Analysis");
   Dialog.addNumber("Number of Channels: ", numChannels);
   Dialog.addNumber("Rank of Channel 1: ", channel1);
   Dialog.addString("Name of Channel1: ", name1);
   Dialog.addNumber("Rank of Channel 2: ", channel2);
   Dialog.addString("Name of Channel2: ", name2);
   Dialog.addString("Number of Slides per Sample: ", slidesPerSample);
   Dialog.show();
   numChannels = Dialog.getNumber();
   channel1 = Dialog.getNumber();;
   name1 = Dialog.getString();;;
   channel2 = Dialog.getNumber();;;;
   name2 = Dialog.getString();;;;; 
   slidesPerSample = Dialog.getString();;;;;;

   //asks user for custom settings for analysis
   Dialog.create("Settings for Analysis");
   Dialog.addNumber("Minimum Threshold: ", minThreshold);
   Dialog.addNumber("Maximum Threshold: ", maxThreshold);
   Dialog.addNumber("# of Smooth: ", numSmooth);
   Dialog.addNumber("# of Sharpen: ", numSharpen);
   Dialog.addString("Minimum Size of Cells: ", minSize);
   Dialog.show();
   minThreshold = Dialog.getNumber();
   maxThreshold = Dialog.getNumber();;
   numSmooth = Dialog.getNumber();;;
   numSharpen = Dialog.getNumber();;;;
   minSize = Dialog.getString();;;;;

   dirResults = getDirectory("Choose a Results folder");

   processFiles(dir, dirResults);

   //makes a new folder to put in a final text file that has data on every image
   File.makeDirectory(dirResults + "Data");
   f = File.open(dirResults + "Data/AllResults.txt");
   print(f, name1 + "+ " + name2 + "+\tNames");
   for (i=0; i<data.length; i++) {
      print(f, data[i] + "\t\t" + names[i]);
      if ((i+1)%slidesPerSample == 0 && i > 1) {
         total = 0;
         for (j = 0; j < slidesPerSample; j++) 
            total += data[i-j];
         print(f, "Average: " + total / slidesPerSample);
      }
   }
   print(f, "\n");
   print(f, "Settings used:");
   print(f, "------------");
   print(f, "Number of Channels: " + numChannels);
   print(f, "Channel 1 Order: " + channel1);
   print(f, "Name of Channel 1: " + name1);
   print(f, "Channel 2 Order: " + channel2);
   print(f, "Name of Channel 2: " + name2);
   print(f, "Slides per Sample: " + slidesPerSample);
   print(f, "");
   print(f, "Minimum Threshold: " + minThreshold);
   print(f, "Maximum Threshold: "+ maxThreshold);
   print(f, "# of Smooths: " + numSmooth);
   print(f, "# of Sharpens: " + numSharpen);
   print(f, "Minimum Cell size: " + minSize);
   
   //goes through every image and makes a new folder to put results in
   function processFiles(dir, dirResults) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          path = "" + dir + list[i];
          print(path);
          name = substring(list[i], 0, lengthOf(list[i]) - 4);
          names = append(names, name);
          File.makeDirectory(dirResults + name);
          processFile(path, name, i, dirResults);
      }
  }

  //for adding values to an array
  function append(arr, value) {
      arr2 = newArray(arr.length+1);
      for (i=0; i<arr.length; i++)
          arr2[i] = arr[i];
      arr2[arr.length] = value;
      return arr2;
  }

  //deletes unnecesssary channels for image
  function selectSlice(path, total, n) {
      open(path);
      for (i=1; i<n; i++) {
           run("Delete Slice", "delete=channel");
      }
      for (i=n; i<total; i++) {
           run("Next Slice [>]");
           run("Delete Slice", "delete=channel");
      }
  }


  function processFile(path, name, number, dirResults) {
           open(path);

           //saves the image as two separate images for downstream analysis
           saveAs("Tiff", dirResults + name + name1 + ".tif");
           saveAs("Tiff", dirResults + name + name2 + ".tif");
           close();

           //Removes unnecessary channels from first channel and thresholds it
           selectSlice(dirResults + name + name1 + ".tif", numChannels, channel1);
           selectWindow(name + name1 + ".tif");
           run("Threshold...");
           setAutoThreshold("Default dark");
           call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
           selectWindow("Threshold");
           run("Close");
           selectWindow(name + name1 + ".tif");
           run("Save");
           saveAs("Tiff", dirResults + name + "/" + name1 + ".tif");

           //Removes unnecessary channels from second channel and thresholds it
           selectSlice(dirResults + name + name2 + ".tif", numChannels, channel2);
           selectWindow(name + name2 + ".tif");
           run("Threshold...");
           setAutoThreshold("Default dark");
           call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
           selectWindow("Threshold");
           run("Close");
           selectWindow(name + name2 + ".tif");
           run("Save");
           saveAs("Tiff", dirResults + name + "/" + name2 + ".tif");

           //uses AND function to look for double counted cells
           open(dirResults + name + name1 + ".tif");
           open(dirResults + name + name2 + ".tif");
           imageCalculator("AND create", name + name1 + ".tif", name + name2 + ".tif");

           //makes image brighter by setting threshold to user specified min and max threshold and smooths it out 
           run("Threshold...");
           //setAutoThreshold("Default dark");
           //call("ij.plugin.frame.ThresholdAdjuster.setMode", "B&W");
           setThreshold(minThreshold, maxThreshold);
           selectWindow("Threshold");
           run("Close");
           selectWindow("Result of " + name + name1 + ".tif");
           for (i=0; i<numSharpen; i++)
              run("Sharpen");
           for (i=0; i<numSmooth; i++)
              run("Smooth");
           
           //Counts double counted cells and saves results
           run("Analyze Particles...", "size=" + minSize + "-Infinity display exclude clear include add in_situ");
           selectWindow("Result of " + name + name1 + ".tif");
           saveAs("Tiff",  dirResults + name + "/double.tif");
           selectWindow("Results");

           saveAs("Results", dirResults + name + "/Results.csv");
           n = nResults;
           data = append(data, n);

           run("Close");

           //deletes unnecessary intermediate files
           a = File.delete(dirResults + name + name1 + ".tif");
           b = File.delete(dirResults + name + name2 + ".tif");
  }

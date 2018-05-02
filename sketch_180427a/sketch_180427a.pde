import themidibus.*;
import javax.sound.midi.MidiMessage; 
import java.util.Arrays;
import java.util.List;

//Midi config
//Look at console to see available midi inputs and set
//the index of your midi device here
//TODO:  use gui to select midi input device
int midiDevice  = 0;

MidiBus myBus;

//ordering here dictates correspondence to pads according to the following:
// BOTTOM_RIGHT // BOTTOM_LEFT // TOP_LEFT // TOP_RIGHT
Integer[] notes = {85, 84, 80, 82};

//midi controller specific
final int NUM_PADS = notes.length;
final int MAX_VELOCITY = 128;
final int MAX_JUMP = 200;
final int MIN_JUMP = 50;

//image files settings
final int MAX_FILES = 128;
final String dataDir = "/data/";
final List<String> allowedExtensions = Arrays.asList("jpg", "png", "pdf");

//Only using one of the elements in each of these arraylists, but kept for future usage
ArrayList<Integer> newDestinations; //updated by midi callback
ArrayList<Boolean> padWasPressed; //flags indicating a pad was pressed, also updated by callback

int numFrames = 0;  // The number of frames in the animation
int currentFrame = 0;
PImage[] images;
int offset = 0;

void setup() {
  size(640, 360);
  frameRate(30);

  //setup midi
  MidiBus.list();
  myBus = new MidiBus(this, midiDevice, 1); 

  //initialize variables set by midi callback
  newDestinations = new ArrayList<Integer>();
  padWasPressed = new ArrayList<Boolean>();
  for ( int pad = 0; pad < NUM_PADS; pad++) {
    newDestinations.add(0);
    padWasPressed.add(false);
  }
  // FILES
  String path = sketchPath();
  String[] filenames = listFileNames(path + dataDir);
  filenames = sort(filenames);
  
  //filter out files that dont have allowed extensions
  List<String> filteredList = filterFilenames(Arrays.asList(filenames), allowedExtensions);
  
  //numFiles is number of available files in folder. All of them might not be used.
  int numFiles = filteredList.size();
  if (numFiles > MAX_FILES){
    filteredList.subList(MAX_FILES, numFiles).clear();
  }
  
  //create final filename list
  String[] filteredFilenames = new String[filteredList.size()];
  filteredList.toArray(filteredFilenames); 
  
  //numFrames is actual number of files loaded by app.
  numFrames = filteredFilenames.length;
  images = new PImage[numFrames];
  for (int i = 0; i < numFrames; i += 1) {
    images[i] = loadImage(path + dataDir + filteredFilenames[i]);
  }
} 

void draw() { 
  background(0);

  if (offset > width) {
    offset = 0;
    currentFrame = (currentFrame + 1) % numFrames;  // Use % to cycle through frames
    newDestinations.set(0, newDestinations.get(0) - width);
    println(currentFrame);
  }
  offset = Math.round(lerp(offset, newDestinations.get(0), 0.05));
  image(images[currentFrame], offset, 0, width, height);
  image(images[(currentFrame+1) % numFrames], offset - width, 0, width, height);
}

// This function returns all the files in a directory as an array of Strings  
String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } else {
    // If it's not a directory
    return null;
  }
}

//Called by MidiBus library whenever a new midi message is received
void midiMessage(MidiMessage message) { 
  int note = (int)(message.getMessage()[1] & 0xFF) ;
  int vel = (int)(message.getMessage()[2] & 0xFF);
  println("note: " + note + " vel: "+ vel);

  int pad = noteToPad(note);
  if (pad >= 0 && (vel > 0)) {
    padWasPressed.set(pad, true);
    newDestinations.set(pad, offset + Math.round(map(constrain(vel, 0, MAX_VELOCITY), 0, MAX_VELOCITY, MIN_JUMP, MAX_JUMP)));
  }
}

int noteToPad (int note) {
  return Arrays.asList(notes).indexOf(note);
}

private static String getFileExtension(String filename) {
  String extension = "";
  int i = filename.lastIndexOf('.');
  if (i > 0) {
    extension = filename.substring(i+1);
  }   
  return extension;
}

private static List<String> filterFilenames(List<String> names, List<String> allowed) {

  List<String> result = new ArrayList<String>();
  for (String name : names) {
    if (allowed.contains(getFileExtension(name))) {
      result.add(name);
    }
  }
  return result;
}

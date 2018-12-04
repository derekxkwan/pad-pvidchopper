import processing.video.*;
import themidibus.*;

int num_movies = 8;
Boolean ignore_noteoff = true;
int note_dur = 1000; //used if ignore_noteoff used, in millis

String[] file_src = {
                     "the-nation-at-your-fingertips-1951-10mbps.mp4",
                     "the-nation-at-your-fingertips-1951-10mbps.mp4",
                     "the-nation-at-your-fingertips-1951-10mbps.mp4",
                     "the-nation-at-your-fingertips-1951-10mbps.mp4",
                     "the-nation-at-your-fingertips-1951-10mbps.mp4",
                     "the-nation-at-your-fingertips-1951-10mbps.mp4",
                     "the-nation-at-your-fingertips-1951-10mbps.mp4",
                     "the-nation-at-your-fingertips-1951-10mbps.mp4"};
float[] pos = {0.3, 0.5, 0.24, 0.89, 0.45, 0.12, 0.76, 0.55};
float[] rate = {1, 1, 1, 1, 1, 1, 1, 1};
Boolean[] playing = {false, false, false, false, false, false, false, false};

Movie[] movies = new Movie[num_movies];

float[] file_durs = new float[8];

MidiBus myBus;

float default_vol = 0.25;
float vid_width;
float vid_height;
float aspect_rto = 0.75;

int per_row = 4; //vids per row
float[] topleft_x = {0, 0, 0, 0, 0, 0, 0, 0};
float [] topleft_y = {0, 0, 0, 0, 0, 0, 0, 0};
int[] grid_order = {4, 5, 6, 7, 0, 1, 2, 3}; // grid_order starting from top left ( 4 x 2)
NoteThread[] note_threads = new NoteThread[num_movies];
int low_thresh = 10; //low threshold for thread check in millis

void setup()
{

  float start_y; // y_coord to start video grid
 size(2048,1536);
 frameRate(24);
 vid_width = width/float(per_row);
 vid_height = vid_width *  aspect_rto;
 start_y = height/2.0 - vid_height;


 for(int i = 0; i < num_movies; i++)
 {
   //figuring out position
   int grid_idx = grid_order[i]; //order in actual grid (counting from top-lefft)
   int cur_row = int(grid_idx / per_row);
   int cur_col = grid_idx % per_row;

   topleft_x[i] = cur_col * vid_width;
   topleft_y[i] = start_y + (cur_row * vid_height);

   // movie loading
   movies[i] = new Movie(this, file_src[i]);
   movies[i].speed(1.0);
   file_durs[i] = movies[i].duration();
   movies[i].volume(default_vol);
   movies[i].speed(rate[i]);
   note_threads[i] = new NoteThread(i);

 };

 
 MidiBus.list();
 myBus = new MidiBus(this, "Wireless [hw:1,0,0]", -1);
 //play_all(true);
 
}

void draw()
{
  background(0);
  for(int i = 0; i < num_movies; i++)
  {
    Boolean is_playing = playing[i];
    if(is_playing == true)
    {
      float cur_x = topleft_x[i];
      float cur_y = topleft_y[i];

      image(movies[i], cur_x, cur_y, vid_width, vid_height);
    };
    

  };
}

int note_to_idx(int note)
{
  return note - 36;
}

void movieEvent(Movie m) {
  m.read();
}


void play_video(int idx, Boolean to_play)
{
  // println("" + idx + ":" + to_play);
  if(to_play == true)
  {
    float jump_to; 
    movies[idx].play();
    jump_to = pos[idx] * movies[idx].duration();
    movies[idx].jump(jump_to);

    if(playing[idx] == false)
    {
      playing[idx] = true;
      if(ignore_noteoff == true)
      {

        note_threads[idx].new_noteon();
        if(note_threads[idx].is_running() == false)
        {
          note_threads[idx].start();
        }
        
        //thread("noteoff_callback", idx);
      };

    };
  }
  else
  {
    //note_threads[idx].zero_dur();
    movies[idx].stop();
    playing[idx] = false;
    if(ignore_noteoff == true)
    {
      note_threads[idx] = new NoteThread(idx);
    };
  };
}

void play_all(Boolean to_play)
{
  for(int i = 0; i < num_movies; i++)
  {
    play_video(i, to_play);
  };
}

void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  int mov_idx = note_to_idx(pitch);
  play_video(mov_idx, true);
  /*
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
  */
  
}

void noteOff(int channel, int pitch, int velocity) {
  // Receive a noteOff
  /*
  println();
  println("Note Off:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
  */
}

void controllerChange(int channel, int number, int value) {
  // Receive a controllerChange
  println();
  println("Controller Change:");
  println("--------");
  println("Channel:"+channel);
  println("Number:"+number);
  println("Value:"+value);
}


public class NoteThread extends Thread
{
  int idx,  dur_left, last_noteon;
  Boolean amirunning;
  NoteThread(int cur_idx)
  {
    dur_left = 0;
    last_noteon = millis();
    amirunning = false;
    idx = cur_idx;
  }

  public Boolean is_running()
  {
    return this.amirunning;
  }

  public void start_thread()
  {
    this.amirunning = true;
    super.start();
  }

  public void new_noteon()
  {
    int cur_new= millis();
    int since_last= min(note_dur, cur_new- last_noteon);
    this.last_noteon = cur_new;
    this.dur_left += since_last;
    //println("" + idx + " adding " + since_last);
  }

  
  void run()
{

  while(this.dur_left > low_thresh)
  {
    int cur_durleft = this.dur_left;
    delay(cur_durleft);
    this.dur_left -= cur_durleft;
  };
  this.amirunning = false;
  this.dur_left = 0;
  play_video(this.idx, false);
};

}
